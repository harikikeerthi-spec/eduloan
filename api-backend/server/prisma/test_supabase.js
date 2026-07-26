require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in environment');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function main() {
    console.log('Querying User table columns and records...');
    const { data: users, error } = await supabase
        .from('User')
        .select('*')
        .limit(5);

    if (error) {
        console.error('Error fetching users:', error);
        return;
    }

    console.log(`Successfully fetched ${users.length} users.`);
    if (users.length > 0) {
        // Inspect the first user's keys to see what column names are present
        console.log('User model columns in database:', Object.keys(users[0]));
        console.log('Sample user record:');
        console.dir(users[0], { depth: null });
        
        // Let's test updating the first user's profileImage
        const testUser = users[0];
        console.log(`\nTesting update of profileImage for user: ${testUser.email}`);
        
        const testImage = 'male_2'; // Test updating with a predefined avatar name
        const { data: updated, error: updateError } = await supabase
            .from('User')
            .update({ profileImage: testImage })
            .eq('id', testUser.id)
            .select();
            
        if (updateError) {
            console.error('Update failed:', updateError);
        } else {
            console.log('Update succeeded. Returned data:');
            console.dir(updated, { depth: null });
            
            // Let's query them again to verify it persisted
            const { data: reloaded } = await supabase
                .from('User')
                .select('profileImage')
                .eq('id', testUser.id)
                .single();
            console.log('Reloaded profileImage value:', reloaded ? reloaded.profileImage : 'Not found');
        }
    }
}

main().catch(console.error);
