require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(supabaseUrl, supabaseKey);

async function findOne(email) {
    const { data, error } = await supabase.from('User').select('*').eq('email', email).single();
    if (error) throw error;
    return data;
}

async function getUserDashboard(email) {
    const user = await findOne(email);
    return {
        success: true,
        user: {
            id: user.id,
            email: user.email,
            firstName: user.firstName || '',
            lastName: user.lastName || '',
            phoneNumber: user.phoneNumber || '',
            profileImage: user.profileImage || null,
        }
    };
}

async function main() {
    const email = 'm87711921@gmail.com';
    console.log(`Testing getUserDashboard for email: ${email}`);
    const result = await getUserDashboard(email);
    console.log('Result returned by backend:');
    console.dir(result, { depth: null });
}

main().catch(console.error);
