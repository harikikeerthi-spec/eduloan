const http = require('https');

const data = JSON.stringify({
  profile: {
    degree: "Master's",
    country: 'USA',
    major: 'Computer Science',
    gpa: '9.0',
    backlogs: 'No',
    backlogCount: '0',
    tests: 'Not yet',
    experience: 'None'
  },
  userId: 'test-user-id-123',
  messages: []
});

const options = {
  hostname: 'appv1.vidyaloans.in',
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
