async function main() {
    const email = 'm87711921@gmail.com';
    const testBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';

    console.log('1. Updating user details with test base64 image...');
    const updateRes = await fetch('http://localhost:5000/api/auth/update-details', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            email: email,
            firstName: 'Test',
            lastName: 'User',
            phoneNumber: '9876543210',
            dateOfBirth: '15-01-1990',
            profileImage: testBase64
        })
    });

    const updateData = await updateRes.json();
    console.log('Update details response:');
    console.dir(updateData, { depth: null });

    console.log('\n2. Querying user dashboard to verify stored image...');
    const dashboardRes = await fetch('http://localhost:5000/api/auth/dashboard', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            email: email
        })
    });

    const dashboardData = await dashboardRes.json();
    console.log('Dashboard response:');
    console.dir(dashboardData, { depth: null });
}

main().catch(console.error);
