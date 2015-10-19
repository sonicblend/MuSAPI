# MuSAPI
Music Search API (alpha)

It's difficult to find quality previews of music, particularly around release date. MuSAPI aims to simplify searching multiple sources through a standard RESTful search interface, and return results in a standardised JSON format.

Currently Deezer and Bandcamp are implemented.

<code>GET /search/deezer/artist - title</code>

```json
{
    "artist": "QUANTA",
    "link": "http:\/\/www.deezer.com\/album\/9547378",
    "title": "Connecting Patterns"
}
```

<code>GET /search/bandcamp/liquid stranger - the intergalactic slapstick</code>

```json
{
    "link": "https:\/\/liquidstranger.bandcamp.com\/album\/the-intergalactic-slapstick",
    "title": "The Intergalactic Slapstick | Liquid Stranger"
}
```

## To install and run

Tested using perl 5.22.0, redis 3.05 and cpanm:

```
cpanm --installdeps .
perl script/musapi daemon
```

The above serves a website at 127.0.0.1:3000

Alternately MuSAPI can be run on the command-line:

```
perl script/musapi get '/search/bandcamp/quanta - connecting patterns'
```
