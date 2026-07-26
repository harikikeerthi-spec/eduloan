"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    const loans = await prisma.loanApplication.findMany({
        include: {
            user: true,
        },
    });
    console.log('Total loans:', loans.length);
    console.log(JSON.stringify(loans, null, 2));
    const users = await prisma.user.findMany({
        select: { id: true, email: true, firstName: true, lastName: true }
    });
    console.log('Total users:', users.length);
    console.log(JSON.stringify(users, null, 2));
}
main()
    .catch((e) => {
    console.error(e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=check_loans.js.map