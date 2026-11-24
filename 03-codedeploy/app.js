const http = require('node:http');
function createServer() {
  return http.createServer((req, res) => {
    const path = new URL(req.url, 'http://localhost').pathname;
    res.setHeader('Content-Type', 'application/json');
    if (req.method !== 'GET') { res.writeHead(405); res.end(JSON.stringify({error:'Method not allowed'})); return; }
    if (path === '/') { res.end(JSON.stringify({message:'AWS Academy CI/CD demo', version:'1.0.0', environment:process.env.APP_ENV || 'development'})); }
    else if (path === '/health') { res.end(JSON.stringify({status:'ok'})); }
    else { res.writeHead(404); res.end(JSON.stringify({error:'Not found'})); }
  });
}
if (require.main === module) createServer().listen(Number(process.env.PORT || 8080), '0.0.0.0');
module.exports = {createServer};
