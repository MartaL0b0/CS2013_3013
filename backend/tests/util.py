import urllib.parse

from lxml import etree

def extract_email_html_link(response, suffix=''):
    data = response.json()
    parser = etree.HTMLParser()
    tree = etree.fromstring(data['html'], parser=parser)
    a_node = next(filter(lambda a: a.attrib['href'].find('http') != -1, tree.findall('.//a')))
    return {f'email_link{suffix}': a_node.attrib['href']}

def extract_email_html_link_token(response, suffix=''):
    url = extract_email_html_link(response)['email_link']
    parsed = urllib.parse.urlparse(url)
    qs = urllib.parse.parse_qs(parsed.query)
    return {f'email_link{suffix}': url, f'email_token{suffix}': qs['token'][0]}
