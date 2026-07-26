const http = require('http');

const data = JSON.stringify({
  userProfile: {
    firstName: 'Keerthi',
    lastName: 'Hari',
    localTime: '2026-06-14T21:41:00Z',
    localHour: 21
  },
  visaType: 'F1 Student Visa',
  agentType: 'agent_michael'
});

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/ai/visa-interview/start',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log('STATUS:', res.statusCode);
    console.log('HEADERS:', res.headers);
    console.log('BODY:', body);
  });
});

req.on('error', (e) => {
  console.error(`problem with request: ${e.message}`);
});

req.write(data);
req.end();
