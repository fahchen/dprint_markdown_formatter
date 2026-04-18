use dprint_core::configuration::NewLineKind;
use dprint_plugin_markdown::configuration::{
    Configuration, EmphasisKind, HeadingKind, StrongKind, TextWrap, UnorderedListKind,
};
use dprint_plugin_markdown::format_text;
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
    heading_kind,
    always,
    never,
    maintain,
    asterisks,
    underscores,
    auto,
    lf,
    crlf,
    dashes,
    atx,
    setext,
}

/// Simple NIF function that receives a config map from Elixir
/// The map contains only the 7 dprint-related fields (no format_module_attributes)
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
    let heading_kind = build_heading_kind(&map)?;

    Ok(Configuration {
        line_width,
        text_wrap,
        emphasis_kind,
        strong_kind,
        new_line_kind,
        unordered_list_kind,
        heading_kind,
        tags: HashMap::new(),
        ignore_directive: "dprint-ignore".to_string(),
        ignore_start_directive: "dprint-ignore-start".to_string(),
        ignore_end_directive: "dprint-ignore-end".to_string(),
        ignore_file_directive: "dprint-ignore-file".to_string(),
    })
}

/// Decode an atom-valued config entry into a target enum variant.
macro_rules! build_enum_option {
    (
        $fn_name:ident,
        $key:ident,
        $ret:ty,
        { $( $atom_fn:ident => $variant:expr ),+ $(,)? }
    ) => {
        fn $fn_name(map: &HashMap<Atom, Term>) -> Result<$ret, String> {
            let decoded = map
                .get(&$key())
                .ok_or_else(|| format!("Missing {}", stringify!($key)))?
                .decode::<Atom>()
                .map_err(|_| format!("Invalid {}", stringify!($key)))?;

            match decoded {
                $( atom if atom == $atom_fn() => Ok($variant), )+
                _ => Err(format!("Invalid {} value", stringify!($key))),
            }
        }
    };
}

build_enum_option!(build_text_wrap, text_wrap, TextWrap, {
    always => TextWrap::Always,
    never => TextWrap::Never,
    maintain => TextWrap::Maintain,
});

build_enum_option!(build_emphasis_kind, emphasis_kind, EmphasisKind, {
    asterisks => EmphasisKind::Asterisks,
    underscores => EmphasisKind::Underscores,
});

build_enum_option!(build_strong_kind, strong_kind, StrongKind, {
    asterisks => StrongKind::Asterisks,
    underscores => StrongKind::Underscores,
});

build_enum_option!(build_new_line_kind, new_line_kind, NewLineKind, {
    auto => NewLineKind::Auto,
    lf => NewLineKind::LineFeed,
    crlf => NewLineKind::CarriageReturnLineFeed,
});

build_enum_option!(build_unordered_list_kind, unordered_list_kind, UnorderedListKind, {
    dashes => UnorderedListKind::Dashes,
    asterisks => UnorderedListKind::Asterisks,
});

build_enum_option!(build_heading_kind, heading_kind, HeadingKind, {
    atx => HeadingKind::Atx,
    setext => HeadingKind::Setext,
});

rustler::init!("Elixir.DprintMarkdownFormatter.Native");
