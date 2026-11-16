/**
 * Source text with its comments removed, for checks that ask what code uses:
 * a name in a comment is not a use. Reads Rust and the JavaScript family alike.
 *
 * `//` line comments and `/* … *\/` block comments go; string and template
 * literals stay, so a `//` inside one is not a comment. A `'` opens a literal
 * only when it closes on the same line, since in Rust it also marks a lifetime.
 * A block comment's newlines are kept, so every line keeps its number.
 */
export function withoutComments(text) {
  let out = '';
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    const next = text[i + 1];
    if (c === '/' && next === '/') {
      while (i < text.length && text[i] !== '\n') i++;
    } else if (c === '/' && next === '*') {
      i += 2;
      while (i < text.length && !(text[i] === '*' && text[i + 1] === '/')) {
        if (text[i] === '\n') out += '\n';
        i++;
      }
      i += 2;
    } else if (c === '"' || c === '`' || (c === "'" && closesOnLine(text, i))) {
      const end = literalEnd(text, i);
      out += text.slice(i, end);
      i = end;
    } else {
      out += c;
      i++;
    }
  }
  return out;
}

/** The index just past the literal that opens at `start`. */
function literalEnd(text, start) {
  const quote = text[start];
  let i = start + 1;
  while (i < text.length && text[i] !== quote) i += text[i] === '\\' ? 2 : 1;
  return i + 1;
}

function closesOnLine(text, start) {
  for (let i = start + 1; i < text.length && text[i] !== '\n'; i += text[i] === '\\' ? 2 : 1) {
    if (text[i] === "'") return true;
  }
  return false;
}
