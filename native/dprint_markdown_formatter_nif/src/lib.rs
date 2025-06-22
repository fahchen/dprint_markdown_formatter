use dprint_core::configuration::NewLineKind;
use dprint_plugin_markdown::{configuration::Configuration, format_text};

#[rustler::nif]
fn format_markdown(text: String) -> Result<String, String> {
    // Create default configuration for markdown formatting
    let config = Configuration {
        line_width: 80,
        text_wrap: dprint_plugin_markdown::configuration::TextWrap::Always,
        emphasis_kind: dprint_plugin_markdown::configuration::EmphasisKind::Asterisks,
        strong_kind: dprint_plugin_markdown::configuration::StrongKind::Asterisks,
        new_line_kind: NewLineKind::Auto,
        unordered_list_kind: dprint_plugin_markdown::configuration::UnorderedListKind::Dashes,
        ignore_directive: "dprint-ignore".to_string(),
        ignore_start_directive: "dprint-ignore-start".to_string(),
        ignore_end_directive: "dprint-ignore-end".to_string(),
        ignore_file_directive: "dprint-ignore-file".to_string(),
    };

    // Format the text using dprint-plugin-markdown
    match format_text(&text, &config, |_, _, _| Ok(None)) {
        Ok(Some(formatted)) => Ok(formatted),
        Ok(None) => Ok(text), // No changes needed
        Err(e) => Err(format!("Formatting error: {}", e)),
    }
}

rustler::init!("Elixir.DprintMarkdownFormatter.Native");
