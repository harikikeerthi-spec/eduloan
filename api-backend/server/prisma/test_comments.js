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
    // 1. Get a user to act as author
    const { data: users, error: userError } = await supabase.from('User').select('id').limit(1);
    if (userError || users.length === 0) {
        console.error('No users found in database to act as author', userError);
        return;
    }
    const userId = users[0].id;
    console.log('Using userId:', userId);

    // 2. Create a test post
    console.log('Inserting test ForumPost...');
    const { data: post, error: postError } = await supabase.from('ForumPost').insert({
        title: 'Test Post for Replies',
        content: 'This is a test post content',
        category: 'General',
        authorId: userId,
        updatedAt: new Date().toISOString()
    }).select().single();

    if (postError) {
        console.error('Error inserting ForumPost:', postError);
        return;
    }
    console.log('Inserted post ID:', post.id);

    try {
        // 3. Create a parent comment
        console.log('Inserting parent comment...');
        const { data: parentComment, error: parentCommentError } = await supabase.from('ForumComment').insert({
            content: 'This is a parent comment',
            postId: post.id,
            authorId: userId,
            updatedAt: new Date().toISOString()
        }).select().single();

        if (parentCommentError) {
            console.error('Error inserting parent comment:', parentCommentError);
            return;
        }
        console.log('Inserted parent comment ID:', parentComment.id);

        // 4. Create a reply comment
        console.log('Inserting reply comment...');
        const { data: replyComment, error: replyCommentError } = await supabase.from('ForumComment').insert({
            content: 'This is a reply to the parent comment',
            postId: post.id,
            authorId: userId,
            parentId: parentComment.id,
            updatedAt: new Date().toISOString()
        }).select().single();

        if (replyCommentError) {
            console.error('Error inserting reply comment:', replyCommentError);
            return;
        }
        console.log('Inserted reply comment ID:', replyComment.id);

        // 5. Query the post with the replies select query
        console.log('\nQuerying details for post ID...');
        const queryStr = '*, author:User!authorId(firstName, lastName, id, role), comments:ForumComment!postId(*, author:User!authorId(firstName, lastName, id, role), replies:ForumComment!parentId(*, author:User!authorId(firstName, lastName, id, role)))';
        
        const { data: postDetail, error: detailError } = await supabase
            .from('ForumPost')
            .select(queryStr)
            .eq('id', post.id)
            .single();
            
        if (detailError) {
            console.error('Error fetching post detail:', detailError);
        } else {
            console.log('Successfully fetched post detail!');
            console.log('Post comments structure:');
            console.dir(postDetail.comments, { depth: null });
            
            // Apply the service filtering logic
            const topLevelComments = (postDetail.comments || []).filter((c) => !c.parentId);
            console.log('\nFiltered topLevelComments:');
            console.dir(topLevelComments, { depth: null });
        }
    } finally {
        // Clean up
        console.log('\nCleaning up test post...');
        await supabase.from('ForumPost').delete().eq('id', post.id);
    }
}

main().catch(console.error);
