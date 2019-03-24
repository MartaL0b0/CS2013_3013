import urllib.parse

from lxml import etree

def extract_email_html_link(response):
    data = response.json()
    parser = etree.HTMLParser()
    tree = etree.fromstring(data['html'], parser=parser)
    a_node = tree.findall('.//a')[0]
    return {'email_link': a_node.attrib['href']}

def extract_email_html_link_token(response):
    url = extract_email_html_link(response)['email_link']
    parsed = urllib.parse.urlparse(url)
    qs = urllib.parse.parse_qs(parsed.query)
    return {'email_link': url, 'email_token': qs['token'][0]}
