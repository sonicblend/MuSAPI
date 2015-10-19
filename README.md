# MuSAPI
Music Search API (alpha)

It's difficult to find quality previews of music, particularly around release date. MuSAPI aims to simplify searching multiple sources through a standard RESTful search interface, and return results in a standardised JSON format.

Currently Deezer and Bandcamp are implemented.

<code>GET /search/bandcamp/liquid stranger - the intergalactic slapstick</code>

```json
{"link":"https:\/\/liquidstranger.bandcamp.com\/album\/the-intergalactic-slapstick","title":"The Intergalactic Slapstick | Liquid Stranger"}
```

<code>GET /search/deezer/artist - title</code>

```json
{"title":"Connecting Patterns | Quanta","link":"https:\/\/quanta-dub.bandcamp.com\/album\/connecting-patterns"}
```

## To install and run

Tested using perl 5.22.0, redis 3.05 and cpanm:

```
cpanm --installdeps .
perl script/musapi daemon
```

Or on the command-line:

```
perl script/musapi get '/search/bandcamp/quanta - connecting patterns'
```
