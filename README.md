# MuSAPI
Music Search API (alpha)

It's difficult to find quality previews of music, particularly around release date. MuSAPI aims to simplify searching multiple sources through a standard RESTful search interface.

### Bandcamp
<code>GET /search/bandcamp/artist - title</code>
### Deezer
<code>GET /search/deezer/artist - title</code>

Where <code>artist - title</code> is the query string.

At the moment search results aren't standardised.

## To install and run

Tested using perl 5.22.0, redis 3.05 and cpanm:

<code>cpanm --installdeps .

perl script/musapi daemon</code>
