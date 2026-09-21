"""Validate built site links, anchors, local assets and document headings."""
from html.parser import HTMLParser
from pathlib import Path
import sys
from urllib.parse import unquote, urljoin, urlsplit


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.ids = set()
        self.links = []
        self.headings = 0
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'h1':
            self.headings += 1
        attr = 'href' if tag in ('a', 'link') else 'src'
        if tag in ('a', 'link', 'script', 'img') and attrs.get(attr):
            self.links.append(attrs[attr])


def main():
    root = Path(sys.argv[1]).resolve()
    base = sys.argv[2].rstrip('/') if len(sys.argv) > 2 else ''
    pages = {p: Page(p.read_text()) for p in root.rglob('*.html')}
    errors = []
    for path, page in pages.items():
        rel = path.relative_to(root).as_posix()
        url = base + '/' + (rel[:-10] if rel.endswith('index.html') else rel)
        if page.headings != 1:
            errors.append(f'{rel}: expected one h1, found {page.headings}')
        for link in page.links:
            parsed = urlsplit(urljoin(url, link))
            if parsed.scheme or parsed.netloc:
                continue
            decoded = unquote(parsed.path)
            if base and not (decoded == base or decoded.startswith(base + '/')):
                errors.append(f'{rel}: link outside project base: {link}')
                continue
            target = root / decoded[len(base):].lstrip('/')
            if target.is_dir():
                target /= 'index.html'
            if not target.exists():
                errors.append(f'{rel}: missing {link}')
            elif parsed.fragment and target in pages and unquote(parsed.fragment) not in pages[target].ids:
                errors.append(f'{rel}: missing anchor {link}')
    if not pages:
        errors.append('No HTML pages built')
    if errors:
        print('\n'.join(errors))
        return 1
    print(f'Validated {len(pages)} pages: internal links, anchors, assets and h1 headings.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
