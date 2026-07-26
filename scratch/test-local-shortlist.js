const http = require('http');

const data = JSON.stringify({
  profile: {
    degree: "Master's",
    country: 'USA',
    major: 'Computer Science',
    gpa: '9.0',
    backlogs: 'No',
    backlogCount: '0',
    tests: 'GRE: 320, TOEFL: 105',
    experience: '2 years as Software Engineer'
  },
  userId: 'test-user-id-123',
  messages: []
});

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/api/ai/shortlist',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
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
