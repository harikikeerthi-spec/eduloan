const fs = require('fs');
const path = require('path');
const dotenv = require('c:/flutter/projects/Vidhyaloan/api-backend/server/node_modules/dotenv');
const { createClient } = require('c:/flutter/projects/Vidhyaloan/api-backend/server/node_modules/@supabase/supabase-js');

const envPath = 'c:/flutter/projects/Vidhyaloan/api-backend/server/.env';
const config = dotenv.parse(fs.readFileSync(envPath));

const supabaseUrl = config.SUPABASE_URL;
const supabaseKey = config.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing env vars');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function run() {
  console.log('Querying University table where country is India...');
  const { data, error } = await supabase
    .from('University')
    .select('*')
    .ilike('country', '%India%')
    .limit(5);

  if (error) {
    console.error('Supabase error:', error);
  } else {
    console.log('Results (length ' + data.length + '):');
    console.log(JSON.stringify(data, null, 2));
  }
  process.exit(0);
}

run();
