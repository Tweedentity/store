const http = require('http')
const url = require('url')
const osmosis = require('osmosis')

const hostname = '127.0.0.1'
const port = 3132

function getSignature(screenName, id) {
  return osmosis
  .get(`https://twitter.com/${screenName}/status/${id}`)
  .find('meta[property="og:description"]')
  .then(function (context) {
    return Promise.resolve(context.getAttribute('content').replace(/^.{1}|.{1}$/,''))
  })
}

function resError(res) {
  res.statusCode = 500
  res.setHeader('Content-Type', 'text/plain')
  res.end('Error.')
}

const server = http.createServer((req, res) => {

  const pathname = url.parse(req.url).pathname.split('/')
  const screenName = pathname[1]
  const id = pathname[2]
  if (id && /^[a-z0-9_]+$/.test(screenName) && /^\d+$/.test(id)) {
    getSignature(screenName, id)
    .then(content => {
      if (content.lenght == 132) {
        res.statusCode = 200
        res.setHeader('Content-Type', 'text/plain')
        res.end(content)
      } else resError(res)
    })
    .catch(() => resError(res))
  } else resError(res)
})

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`)
})