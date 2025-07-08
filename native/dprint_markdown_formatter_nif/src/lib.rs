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
        .map_err(|e| format!("Formatting failed: {}", e))
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

    let text_wrap = {
        let wrap_atom = map
            .get(&text_wrap())
            .ok_or("Missing text_wrap")?
            .decode::<Atom>()
            .map_err(|_| "Invalid text_wrap")?;

        if wrap_atom == always() {
            dprint_plugin_markdown::configuration::TextWrap::Always
        } else if wrap_atom == never() {
            dprint_plugin_markdown::configuration::TextWrap::Never
        } else if wrap_atom == maintain() {
            dprint_plugin_markdown::configuration::TextWrap::Maintain
        } else {
            return Err("Invalid text_wrap value".to_string());
        }
    };

    let emphasis_kind = {
        let kind_atom = map
            .get(&emphasis_kind())
            .ok_or("Missing emphasis_kind")?
            .decode::<Atom>()
            .map_err(|_| "Invalid emphasis_kind")?;

        if kind_atom == asterisks() {
            dprint_plugin_markdown::configuration::EmphasisKind::Asterisks
        } else if kind_atom == underscores() {
            dprint_plugin_markdown::configuration::EmphasisKind::Underscores
        } else {
            return Err("Invalid emphasis_kind value".to_string());
        }
    };

    let strong_kind = {
        let kind_atom = map
            .get(&strong_kind())
            .ok_or("Missing strong_kind")?
            .decode::<Atom>()
            .map_err(|_| "Invalid strong_kind")?;

        if kind_atom == asterisks() {
            dprint_plugin_markdown::configuration::StrongKind::Asterisks
        } else if kind_atom == underscores() {
            dprint_plugin_markdown::configuration::StrongKind::Underscores
        } else {
            return Err("Invalid strong_kind value".to_string());
        }
    };

    let new_line_kind = {
        let kind_atom = map
            .get(&new_line_kind())
            .ok_or("Missing new_line_kind")?
            .decode::<Atom>()
            .map_err(|_| "Invalid new_line_kind")?;

        if kind_atom == auto() {
            NewLineKind::Auto
        } else if kind_atom == lf() {
            NewLineKind::LineFeed
        } else if kind_atom == crlf() {
            NewLineKind::CarriageReturnLineFeed
        } else {
            return Err("Invalid new_line_kind value".to_string());
        }
    };

    let unordered_list_kind = {
        let kind_atom = map
            .get(&unordered_list_kind())
            .ok_or("Missing unordered_list_kind")?
            .decode::<Atom>()
            .map_err(|_| "Invalid unordered_list_kind")?;

        if kind_atom == dashes() {
            dprint_plugin_markdown::configuration::UnorderedListKind::Dashes
        } else if kind_atom == asterisks() {
            dprint_plugin_markdown::configuration::UnorderedListKind::Asterisks
        } else {
            return Err("Invalid unordered_list_kind value".to_string());
        }
    };

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

rustler::init!("Elixir.DprintMarkdownFormatter.Native");
