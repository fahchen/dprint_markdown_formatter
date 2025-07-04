defmodule Mix.Tasks.Compile.MarkdownFormatterTest do
  use ExUnit.Case

  @moduletag :tmp_dir

  setup :setup_project

  describe "markdown formatting integration" do
    defmacrop compile_project(do: block) do
      quote do
        original_cwd = File.cwd!()

        try do
          File.cd!(var!(tmp_dir))

          System.cmd("mix", ["deps.get"],
            env: [{"RUSTLER_PRECOMPILED_FORCE_BUILD", "true"}],
            into: "",
            stderr_to_stdout: true
          )

          System.cmd("mix", ["format"],
            env: [{"RUSTLER_PRECOMPILED_FORCE_BUILD", "true"}],
            into: "",
            stderr_to_stdout: true
          )

          System.cmd("mix", ["compile"],
            env: [{"RUSTLER_PRECOMPILED_FORCE_BUILD", "true"}],
            into: "",
            stderr_to_stdout: true
          )

          unquote(block)
        after
          File.cd!(original_cwd)
        end
      end
    end

    # Generate tests for each case file using Path.wildcard
    for case_file_path <- Path.wildcard(Path.join([__DIR__, "cases", "*.ex"])) do
      test_name = String.replace(Path.basename(case_file_path, ".ex"), "_", " ")

      test "formats #{test_name}", %{tmp_dir: tmp_dir} do
        test_case_path = unquote(case_file_path)
        expected_path = "#{unquote(case_file_path)}.formatted"

        project_file_path = Path.join([tmp_dir, "lib", "test_module.ex"])
        File.cp!(test_case_path, project_file_path)

        compile_project do
          formatted_content = File.read!(project_file_path)
          expected_content = File.read!(expected_path)

          assert formatted_content == expected_content
        end
      end
    end
  end

  # Private helpers
  defp setup_project(context) do
    %{tmp_dir: tmp_dir} = context

    # Manifest will be stored in the project's _build directory
    manifest_path =
      Path.join([tmp_dir, "_build", "test", "lib", "test_project", "compile.markdown_formatter"])

    # Default project files
    default_files = [
      # make a directory for test_module
      "lib/",
      {".formatter.exs", "[inputs: [\"**/*.{ex,exs}\"], plugins: [DprintMarkdownFormatter]]"},
      {"mix.exs",
       """
       defmodule TestProject.MixProject do
         use Mix.Project
         def project do
           [
             app: :test_project,
             version: "0.1.0",
             compilers: [:markdown_formatter] ++ Mix.compilers(),
             deps: deps()
           ]
         end

         defp deps do
           [
             {:dprint_markdown_formatter, path: "#{Path.expand("../../../..", __DIR__)}"}
           ]
         end
       end
       """}
    ]

    # Get accumulated files from registered attribute
    test_files = get_in(context, [:registered, :files]) || []

    # Combine default files with test-specific files (test files can override defaults)
    # Remove duplicates by path, keeping the last occurrence (test files override defaults)
    all_files =
      (default_files ++ test_files)
      |> Enum.reverse()
      |> Enum.uniq_by(fn
        {path, _content} -> path
        path when is_binary(path) -> path
      end)
      |> Enum.reverse()

    # Create all files in the project
    for item <- all_files do
      case item do
        {path, content} -> create_test_file(tmp_dir, path, content)
        path when is_binary(path) -> File.mkdir_p!(Path.join(tmp_dir, path))
      end
    end

    # Return the files list and manifest path for use in tests
    {:ok, files: all_files, manifest_path: manifest_path}
  end

  defp create_test_file(tmp_dir, name, content) do
    file_path = Path.join(tmp_dir, name)
    File.mkdir_p!(Path.dirname(file_path))
    File.write!(file_path, content)
    file_path
  end
end
