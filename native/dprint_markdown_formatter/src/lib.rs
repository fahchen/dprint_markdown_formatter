use dprint_core::configuration::NewLineKind;
use dprint_plugin_markdown::{configuration::Configuration, format_text};
use rustler::{Atom, Term};
use std::collections::HashMap;

// Define atom constants
rustler::atoms! {
    line_width,
    text_wrap,
    emphasis_kind,
    strong_kind,
    new_line_kind,
    unordered_list_kind,
    always,
    never,
    maintain,
    asterisks,
    underscores,
    auto,
    lf,
    crlf,
    dashes,
}

/// Simple NIF function that receives a config map from Elixir
/// The map contains only the 6 dprint-related fields (no format_module_attributes)
/// Elixir is the single source of truth for configuration validation
#[rustler::nif]
fn format_markdown(text: String, config: HashMap<Atom, Term>) -> Result<String, String> {
    // Early return for empty text
    if text.is_empty() {
        return Ok(text);
    }

    // Convert config map to dprint Configuration
    let dprint_config = build_dprint_config(config)?;

    // Format the text using dprint-plugin-markdown
    format_text(&text, &dprint_config, |_, _, _| Ok(None))
        .map_err(|e| format!("Formatting failed: {e}"))
        .map(|result| result.unwrap_or(text))
}

/// Build dprint Configuration from config map provided by Elixir
/// Elixir provides ALL values with proper validation
fn build_dprint_config(map: HashMap<Atom, Term>) -> Result<Configuration, String> {
    let line_width = map
        .get(&line_width())
        .ok_or("Missing line_width")?
        .decode::<u32>()
        .map_err(|_| "Invalid line_width")?;

    let text_wrap = build_text_wrap(&map)?;
    let emphasis_kind = build_emphasis_kind(&map)?;
    let strong_kind = build_strong_kind(&map)?;
    let new_line_kind = build_new_line_kind(&map)?;
    let unordered_list_kind = build_unordered_list_kind(&map)?;

    Ok(Configuration {
        line_width,
        text_wrap,
        emphasis_kind,
        strong_kind,
        new_line_kind,
        unordered_list_kind,
        ignore_directive: "dprint-ignore".to_string(),
        ignore_start_directive: "dprint-ignore-start".to_string(),
        ignore_end_directive: "dprint-ignore-end".to_string(),
        ignore_file_directive: "dprint-ignore-file".to_string(),
    })
}

/// Build text wrap configuration from config map
fn build_text_wrap(
    map: &HashMap<Atom, Term>,
) -> Result<dprint_plugin_markdown::configuration::TextWrap, String> {
    let wrap_atom = map
        .get(&text_wrap())
        .ok_or("Missing text_wrap")?
        .decode::<Atom>()
        .map_err(|_| "Invalid text_wrap")?;

    match wrap_atom {
        atom if atom == always() => Ok(dprint_plugin_markdown::configuration::TextWrap::Always),
        atom if atom == never() => Ok(dprint_plugin_markdown::configuration::TextWrap::Never),
        atom if atom == maintain() => Ok(dprint_plugin_markdown::configuration::TextWrap::Maintain),
        _ => Err("Invalid text_wrap value".to_string()),
    }
}

/// Build emphasis kind configuration from config map
fn build_emphasis_kind(
    map: &HashMap<Atom, Term>,
) -> Result<dprint_plugin_markdown::configuration::EmphasisKind, String> {
    let kind_atom = map
        .get(&emphasis_kind())
        .ok_or("Missing emphasis_kind")?
        .decode::<Atom>()
        .map_err(|_| "Invalid emphasis_kind")?;

    match kind_atom {
        atom if atom == asterisks() => {
            Ok(dprint_plugin_markdown::configuration::EmphasisKind::Asterisks)
        }
        atom if atom == underscores() => {
            Ok(dprint_plugin_markdown::configuration::EmphasisKind::Underscores)
        }
        _ => Err("Invalid emphasis_kind value".to_string()),
    }
}

/// Build strong kind configuration from config map
fn build_strong_kind(
    map: &HashMap<Atom, Term>,
) -> Result<dprint_plugin_markdown::configuration::StrongKind, String> {
    let kind_atom = map
        .get(&strong_kind())
        .ok_or("Missing strong_kind")?
        .decode::<Atom>()
        .map_err(|_| "Invalid strong_kind")?;

    match kind_atom {
        atom if atom == asterisks() => {
            Ok(dprint_plugin_markdown::configuration::StrongKind::Asterisks)
        }
        atom if atom == underscores() => {
            Ok(dprint_plugin_markdown::configuration::StrongKind::Underscores)
        }
        _ => Err("Invalid strong_kind value".to_string()),
    }
}

/// Build new line kind configuration from config map
fn build_new_line_kind(map: &HashMap<Atom, Term>) -> Result<NewLineKind, String> {
    let kind_atom = map
        .get(&new_line_kind())
        .ok_or("Missing new_line_kind")?
        .decode::<Atom>()
        .map_err(|_| "Invalid new_line_kind")?;

    match kind_atom {
        atom if atom == auto() => Ok(NewLineKind::Auto),
        atom if atom == lf() => Ok(NewLineKind::LineFeed),
        atom if atom == crlf() => Ok(NewLineKind::CarriageReturnLineFeed),
        _ => Err("Invalid new_line_kind value".to_string()),
    }
}

/// Build unordered list kind configuration from config map
fn build_unordered_list_kind(
    map: &HashMap<Atom, Term>,
) -> Result<dprint_plugin_markdown::configuration::UnorderedListKind, String> {
    let kind_atom = map
        .get(&unordered_list_kind())
        .ok_or("Missing unordered_list_kind")?
        .decode::<Atom>()
        .map_err(|_| "Invalid unordered_list_kind")?;

    match kind_atom {
        atom if atom == dashes() => {
            Ok(dprint_plugin_markdown::configuration::UnorderedListKind::Dashes)
        }
        atom if atom == asterisks() => {
            Ok(dprint_plugin_markdown::configuration::UnorderedListKind::Asterisks)
        }
        _ => Err("Invalid unordered_list_kind value".to_string()),
    }
}

rustler::init!("Elixir.DprintMarkdownFormatter.Native");
