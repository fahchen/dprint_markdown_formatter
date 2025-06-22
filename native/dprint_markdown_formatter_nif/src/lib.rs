use dprint_core::configuration::NewLineKind;
use dprint_plugin_markdown::{configuration::Configuration, format_text};
use rustler::{Atom, Term};

// Define atom constants for option matching
rustler::atoms! {
    line_width,
    text_wrap,
    emphasis_kind,
    strong_kind,
    new_line_kind,
    unordered_list_kind,
}

#[derive(Debug, Default)]
struct FormatOptions {
    line_width: Option<u32>,
    text_wrap: Option<String>,
    emphasis_kind: Option<String>,
    strong_kind: Option<String>,
    new_line_kind: Option<String>,
    unordered_list_kind: Option<String>,
}

fn parse_options(options: Term) -> FormatOptions {
    let mut format_options = FormatOptions::default();

    // Try decoding as keyword list with atom keys first
    if let Ok(keyword_list) = options.decode::<Vec<(Atom, Term)>>() {
        for (key_atom, value) in keyword_list {
            if key_atom == line_width() {
                if let Ok(width) = value.decode::<u32>() {
                    format_options.line_width = Some(width);
                }
            } else if key_atom == text_wrap() {
                if let Ok(wrap) = value.decode::<String>() {
                    format_options.text_wrap = Some(wrap);
                }
            } else if key_atom == emphasis_kind() {
                if let Ok(kind) = value.decode::<String>() {
                    format_options.emphasis_kind = Some(kind);
                }
            } else if key_atom == strong_kind() {
                if let Ok(kind) = value.decode::<String>() {
                    format_options.strong_kind = Some(kind);
                }
            } else if key_atom == new_line_kind() {
                if let Ok(kind) = value.decode::<String>() {
                    format_options.new_line_kind = Some(kind);
                }
            } else if key_atom == unordered_list_kind() {
                if let Ok(kind) = value.decode::<String>() {
                    format_options.unordered_list_kind = Some(kind);
                }
            }
        }
    } else if let Ok(keyword_list) = options.decode::<Vec<(String, Term)>>() {
        // Fallback: try decoding as keyword list with string keys
        for (key, value) in keyword_list {
            match key.as_str() {
                "line_width" => {
                    if let Ok(width) = value.decode::<u32>() {
                        format_options.line_width = Some(width);
                    }
                }
                "text_wrap" => {
                    if let Ok(wrap) = value.decode::<String>() {
                        format_options.text_wrap = Some(wrap);
                    }
                }
                "emphasis_kind" => {
                    if let Ok(kind) = value.decode::<String>() {
                        format_options.emphasis_kind = Some(kind);
                    }
                }
                "strong_kind" => {
                    if let Ok(kind) = value.decode::<String>() {
                        format_options.strong_kind = Some(kind);
                    }
                }
                "new_line_kind" => {
                    if let Ok(kind) = value.decode::<String>() {
                        format_options.new_line_kind = Some(kind);
                    }
                }
                "unordered_list_kind" => {
                    if let Ok(kind) = value.decode::<String>() {
                        format_options.unordered_list_kind = Some(kind);
                    }
                }
                _ => {} // Ignore unknown options
            }
        }
    }

    format_options
}

#[rustler::nif]
fn format_markdown(text: String, options: Term) -> Result<String, String> {
    let opts = parse_options(options);

    // Create configuration with defaults, overridden by options
    let config = Configuration {
        line_width: opts.line_width.unwrap_or(80),
        text_wrap: match opts.text_wrap.as_deref() {
            Some("never") => dprint_plugin_markdown::configuration::TextWrap::Never,
            Some("maintain") => dprint_plugin_markdown::configuration::TextWrap::Maintain,
            _ => dprint_plugin_markdown::configuration::TextWrap::Always,
        },
        emphasis_kind: match opts.emphasis_kind.as_deref() {
            Some("underscores") => dprint_plugin_markdown::configuration::EmphasisKind::Underscores,
            _ => dprint_plugin_markdown::configuration::EmphasisKind::Asterisks,
        },
        strong_kind: match opts.strong_kind.as_deref() {
            Some("underscores") => dprint_plugin_markdown::configuration::StrongKind::Underscores,
            _ => dprint_plugin_markdown::configuration::StrongKind::Asterisks,
        },
        new_line_kind: match opts.new_line_kind.as_deref() {
            Some("lf") => NewLineKind::LineFeed,
            Some("crlf") => NewLineKind::CarriageReturnLineFeed,
            _ => NewLineKind::Auto,
        },
        unordered_list_kind: match opts.unordered_list_kind.as_deref() {
            Some("asterisks") => {
                dprint_plugin_markdown::configuration::UnorderedListKind::Asterisks
            }
            _ => dprint_plugin_markdown::configuration::UnorderedListKind::Dashes,
        },
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
