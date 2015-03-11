library HTML_Entities;

class HtmlEntities {

  static final Map<String, String> entities = const {
    // from wikipedia: http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
    "\"" : "&quot;",
    //@"&" : "&amp;",
    r"'" : "&apos;",
    r"<" : "&lt;",
    r">" : "&gt;",
    //@" " : "&nbsp;",
    r"¡" : "&iexcl;",
    r"¢" : "&cent;",
    r"£" : "&pound;",
    r"¤" : "&curren;",
    r"¥" : "&yen;",
    r"¦" : "&brvbar;",
    r"§" : "&sect;",
    r"¨" : "&uml;",
    r"©" : "&copy;",
    r"ª" : "&ordf;",
    r"«" : "&laquo;",
    r"¬" : "&not;",
    //@" " : "&shy;",
    r"®" : "&reg;",
    r"¯" : "&macr;",
    r"°" : "&deg;",
    r"±" : "&plusmn;",
    r"²" : "&sup2;",
    r"³" : "&sup3;",
    r"´" : "&acute;",
    r"µ" : "&micro;",
    r"¶" : "&para;",
    r"·" : "&middot;",
    r"¸" : "&cedil;",
    r"¹" : "&sup1;",
    r"º" : "&ordm;",
    r"»" : "&raquo;",
    r"¼" : "&frac14;",
    r"½" : "&frac12;",
    r"¾" : "&frac34;",
    r"¿" : "&iquest;",
    r"À" : "&Agrave;",
    r"Á" : "&Aacute;",
    r"Â" : "&Acirc;",
    r"Ã" : "&Atilde;",
    r"Ä" : "&Auml;",
    r"Å" : "&Aring;",
    r"Æ" : "&AElig;",
    r"Ç" : "&Ccedil;",
    r"È" : "&Egrave;",
    r"É" : "&Eacute;",
    r"Ê" : "&Ecirc;",
    r"Ë" : "&Euml;",
    r"Ì" : "&Igrave;",
    r"Í" : "&Iacute;",
    r"Î" : "&Icirc;",
    r"Ï" : "&Iuml;",
    r"Ð" : "&ETH;",
    r"Ñ" : "&Ntilde;",
    r"Ò" : "&Ograve;",
    r"Ó" : "&Oacute;",
    r"Ô" : "&Ocirc;",
    r"Õ" : "&Otilde;",
    r"Ö" : "&Ouml;",
    r"×" : "&times;",
    r"Ø" : "&Oslash;",
    r"Ù" : "&Ugrave;",
    r"Ú" : "&Uacute;",
    r"Û" : "&Ucirc;",
    r"Ü" : "&Uuml;",
    r"Ý" : "&Yacute;",
    r"Þ" : "&THORN;",
    r"ß" : "&szlig;",
    r"à" : "&agrave;",
    r"á" : "&aacute;",
    r"â" : "&acirc;",
    r"ã" : "&atilde;",
    r"ä" : "&auml;",
    r"å" : "&aring;",
    r"æ" : "&aelig;",
    r"ç" : "&ccedil;",
    r"è" : "&egrave;",
    r"é" : "&eacute;",
    r"ê" : "&ecirc;",
    r"ë" : "&euml;",
    r"ì" : "&igrave;",
    r"í" : "&iacute;",
    r"î" : "&icirc;",
    r"ï" : "&iuml;",
    r"ð" : "&eth;",
    r"ñ" : "&ntilde;",
    r"ò" : "&ograve;",
    r"ó" : "&oacute;",
    r"ô" : "&ocirc;",
    r"õ" : "&otilde;",
    r"ö" : "&ouml;",
    r"÷" : "&divide;",
    r"ø" : "&oslash;",
    r"ù" : "&ugrave;",
    r"ú" : "&uacute;",
    r"û" : "&ucirc;",
    r"ü" : "&uuml;",
    r"ý" : "&yacute;",
    r"þ" : "&thorn;",
    r"ÿ" : "&yuml;",
    r"Œ" : "&OElig;",
    r"œ" : "&oelig;",
    r"Š" : "&Scaron;",
    r"š" : "&scaron;",
    r"Ÿ" : "&Yuml;",
    r"ƒ" : "&fnof;",
    r"ˆ" : "&circ;",
    r"˜" : "&tilde;",
    r"Α" : "&Alpha;",
    r"Β" : "&Beta;",
    r"Γ" : "&Gamma;",
    r"Δ" : "&Delta;",
    r"Ε" : "&Epsilon;",
    r"Ζ" : "&Zeta;",
    r"Η" : "&Eta;",
    r"Θ" : "&Theta;",
    r"Ι" : "&Iota;",
    r"Κ" : "&Kappa;",
    r"Λ" : "&Lambda;",
    r"Μ" : "&Mu;",
    r"Ν" : "&Nu;",
    r"Ξ" : "&Xi;",
    r"Ο" : "&Omicron;",
    r"Π" : "&Pi;",
    r"Ρ" : "&Rho;",
    r"Σ" : "&Sigma;",
    r"Τ" : "&Tau;",
    r"Υ" : "&Upsilon;",
    r"Φ" : "&Phi;",
    r"Χ" : "&Chi;",
    r"Ψ" : "&Psi;",
    r"Ω" : "&Omega;",
    r"α" : "&alpha;",
    r"β" : "&beta;",
    r"γ" : "&gamma;",
    r"δ" : "&delta;",
    r"ε" : "&epsilon;",
    r"ζ" : "&zeta;",
    r"η" : "&eta;",
    r"θ" : "&theta;",
    r"ι" : "&iota;",
    r"κ" : "&kappa;",
    r"λ" : "&lambda;",
    r"μ" : "&mu;",
    r"ν" : "&nu;",
    r"ξ" : "&xi;",
    r"ο" : "&omicron;",
    r"π" : "&pi;",
    r"ρ" : "&rho;",
    r"ς" : "&sigmaf;",
    r"σ" : "&sigma;",
    r"τ" : "&tau;",
    r"υ" : "&upsilon;",
    r"φ" : "&phi;",
    r"χ" : "&chi;",
    r"ψ" : "&psi;",
    r"ω" : "&omega;",
    r"ϑ" : "&thetasym;",
    r"ϒ" : "&upsih;",
    r"ϖ" : "&piv;",
    //@" " : "&ensp;",
    //@" " : "&emsp;",
    //@" " : "&thinsp;",
    //@" " : "&zwnj;",
    //@" " : "&zwj;",
    //@" " : "&lrm;",
    //@" " : "&rlm;",
    r"–" : "&ndash;",
    r"—" : "&mdash;",
    r"‘" : "&lsquo;",
    r"’" : "&rsquo;",
    r"‚" : "&sbquo;",
    r"“" : "&ldquo;",
    r"”" : "&rdquo;",
    r"„" : "&bdquo;",
    r"†" : "&dagger;",
    r"‡" : "&Dagger;",
    r"•" : "&bull;",
    r"…" : "&hellip;",
    r"‰" : "&permil;",
    r"′" : "&prime;",
    r"″" : "&Prime;",
    r"‹" : "&lsaquo;",
    r"›" : "&rsaquo;",
    r"‾" : "&oline;",
    r"⁄" : "&frasl;",
    r"€" : "&euro;",
    r"ℑ" : "&image;",
    r"℘" : "&weierp;",
    r"ℜ" : "&real;",
    r"™" : "&trade;",
    r"ℵ" : "&alefsym;",
    r"←" : "&larr;",
    r"↑" : "&uarr;",
    r"→" : "&rarr;",
    r"↓" : "&darr;",
    r"↔" : "&harr;",
    r"↵" : "&crarr;",
    r"⇐" : "&lArr;",
    r"⇑" : "&uArr;",
    r"⇒" : "&rArr;",
    r"⇓" : "&dArr;",
    r"⇔" : "&hArr;",
    r"∀" : "&forall;",
    r"∂" : "&part;",
    r"∃" : "&exist;",
    r"∅" : "&empty;",
    r"∇" : "&nabla;",
    r"∈" : "&isin;",
    r"∉" : "&notin;",
    r"∋" : "&ni;",
    r"∏" : "&prod;",
    r"∑" : "&sum;",
    r"−" : "&minus;",
    r"∗" : "&lowast;",
    r"√" : "&radic;",
    r"∝" : "&prop;",
    r"∞" : "&infin;",
    r"∠" : "&ang;",
    r"∧" : "&and;",
    r"∨" : "&or;",
    r"∩" : "&cap;",
    r"∪" : "&cup;",
    r"∫" : "&int;",
    r"∴" : "&there4;",
    r"∼" : "&sim;",
    r"≅" : "&cong;",
    r"≈" : "&asymp;",
    r"≠" : "&ne;",
    r"≡" : "&equiv;",
    r"≤" : "&le;",
    r"≥" : "&ge;",
    r"⊂" : "&sub;",
    r"⊃" : "&sup;",
    r"⊄" : "&nsub;",
    r"⊆" : "&sube;",
    r"⊇" : "&supe;",
    r"⊕" : "&oplus;",
    r"⊗" : "&otimes;",
    r"⊥" : "&perp;",
    r"⋅" : "&sdot;",
    r"⌈" : "&lceil;",
    r"⌉" : "&rceil;",
    r"⌊" : "&lfloor;",
    r"⌋" : "&rfloor;",
    r"〈" : "&lang;",
    r"〉" : "&rang;",
    r"◊" : "&loz;",
    r"♠" : "&spades;",
    r"♣" : "&clubs;",
    r"♥" : "&hearts;",
    r"♦" : "&diams;"
    // CZECH
    // TODO: http://tlt.its.psu.edu/suggestions/international/bylanguage/czechslovak.html#htmlcodes
  };

  static String toHtml(String s) {
    entities.forEach((charUtf, entity) {
        s = s.replaceAll(charUtf, entity);
    });
    return s;
  }
}

/*
void main() {
  var s = "Contrary to popular belief, being a young gynaecologist isn’t the bachelor’s dream occupation.";
  print(s);
  print(HtmlEntities.toHtml(s));
}
*/
