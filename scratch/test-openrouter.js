const fs = require('fs');
const path = require('path');

// Manually parse .env file
const envPath = path.join(__dirname, '..', 'api-backend', 'server', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const parts = trimmed.split('=');
      const key = parts[0].trim();
      let val = parts.slice(1).join('=').trim();
      if (val.startsWith('"') && val.endsWith('"')) {
        val = val.slice(1, -1);
      }
      process.env[key] = val;
    }
  });
}

const apiKey = process.env.OPENROUTER_API_KEY;
console.log('Using API Key:', apiKey ? `${apiKey.slice(0, 8)}...` : 'undefined');

const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

async function testModel(model, useJsonMode) {
  console.log(`\n--- Testing Model: ${model} (JSON Mode: ${useJsonMode}) ---`);
  
  const systemPrompt = `You are a Study Abroad Consultant. Recommend 1-2 universities in a JSON array.
  JSON format:
  {
    "recommendations": [
      {
        "name": "Stanford University",
        "chance": "High"
      }
    ]
  }`;

  const body = {
    model: model,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: 'Profile: CGPA 9/10, wants computer science in USA.' }
    ],
    max_tokens: 1000
  };

  if (useJsonMode) {
    body.response_format = { type: 'json_object' };
  }

  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://vidyaloan.com',
        'X-Title': 'VidyaLoan',
      },
      body: JSON.stringify(body)
    });

    console.log('HTTP Status:', response.status, response.statusText);
    const text = await response.text();
    console.log('Raw Response (truncated):', text.slice(0, 500));
    
    if (response.ok) {
      try {
        const data = JSON.parse(text);
        console.log('Result content:', data.choices?.[0]?.message?.content);
      } catch (e) {
        console.log('Parsing result failed');
      }
    }
  } catch (error) {
    console.error('Fetch error:', error);
  }
}

async function run() {
  // Test llama free with JSON mode
  await testModel('meta-llama/llama-3.3-70b-instruct:free', true);
  // Test llama free without JSON mode
  await testModel('meta-llama/llama-3.3-70b-instruct:free', false);
  // Test gpt-4o-mini with JSON mode
  await testModel('openai/gpt-4o-mini', true);
  // Test gemini-2.5-flash with JSON mode
  await testModel('google/gemini-2.5-flash', true);
}

run();
