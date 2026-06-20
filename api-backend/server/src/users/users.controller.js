"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersController = void 0;
const common_1 = require("@nestjs/common");
const users_service_1 = require("./users.service");
const admin_guard_1 = require("../auth/admin.guard");
const email_service_1 = require("../auth/email.service");
let UsersController = class UsersController {
    usersService;
    emailService;
    constructor(usersService, emailService) {
        this.usersService = usersService;
        this.emailService = emailService;
    }
    async getProfile(body) {
        if (!body || !body.email) {
            return {
                success: false,
                message: 'Email is required',
            };
        }
        const user = await this.usersService.findOne(body.email);
        if (!user) {
            return {
                success: false,
                message: 'User not found',
            };
        }
        let formattedDOB = '';
        if (user.dateOfBirth) {
            const date = new Date(user.dateOfBirth);
            const day = String(date.getDate()).padStart(2, '0');
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const year = date.getFullYear();
            formattedDOB = `${day}-${month}-${year}`;
        }
        const safeJsonParse = (str) => {
            if (!str)
                return null;
            try {
                return JSON.parse(str);
            }
            catch (e) {
                return null;
            }
        };
        return {
            success: true,
            user: {
                id: user.id,
                email: user.email,
                firstName: user.firstName || '',
                lastName: user.lastName || '',
                phoneNumber: user.phoneNumber || '',
                dateOfBirth: formattedDOB,
                mobile: user.mobile,
                role: user.role,
                registeredAtIndia: user.registeredAtIndia || '',
                panNumber: user.panNumber || '',
                aadhaarNumber: user.aadhaarNumber || '',
                fatherName: user.fatherName || '',
                permanentAddress: user.permanentAddress || '',
                gender: user.gender || '',
                documentVerified: user.documentVerified || false,
                status: user.status || 'pending',
                rejectionReason: user.rejectionReason || '',
                goal: user.goal || '',
                studyDestination: user.studyDestination || '',
                courseName: user.courseName || '',
                targetUniversity: user.targetUniversity || '',
                intakeSeason: user.intakeSeason || '',
                bachelorsDegree: user.bachelorsDegree || '',
                gpa: user.gpa || null,
                workExp: user.workExp || null,
                entranceTest: user.entranceTest || '',
                entranceScore: user.entranceScore || '',
                englishTest: user.englishTest || '',
                englishScore: user.englishScore || '',
                budget: user.budget || '',
                pincode: user.pincode || '',
                loanAmount: user.loanAmount || '',
                admitStatus: user.admitStatus || '',
                passport: safeJsonParse(user.passport),
                nationality: safeJsonParse(user.nationality),
                mailingAddress: safeJsonParse(user.mailingAddress),
                emergencyContact: safeJsonParse(user.emergencyContact),
                academic: safeJsonParse(user.academic),
                workExperience: safeJsonParse(user.workExperience),
                tests: safeJsonParse(user.tests),
                family: safeJsonParse(user.family),
                coApplicant: safeJsonParse(user.coApplicant),
                createdAt: user.createdAt || user.created_at || '',
            },
        };
    }
    async getUserStats() {
        return this.usersService.getUserStats();
    }
    async listUsers(limit, offset, search, role) {
        console.log('[UsersController.listUsers] Request received', { limit, offset, search, role });
        try {
            const l = limit ? parseInt(limit, 10) : 30;
            const o = offset ? parseInt(offset, 10) : 0;
            console.log('[UsersController.listUsers] Calling usersService.findAll()...');
            const result = await this.usersService.findAll(l, o, search, role);
            const users = result.data;
            console.log(`[UsersController.listUsers] Found ${users?.length || 0} users (Total: ${result.total})`);
            if (!users)
                return { success: true, data: [], total: 0 };
            return {
                success: true,
                data: users.map(u => ({
                    id: u?.id || '',
                    email: u?.email || '',
                    firstName: u?.firstName || '',
                    lastName: u?.lastName || '',
                    phoneNumber: u?.phoneNumber || '',
                    mobile: u?.mobile || '',
                    role: u?.role || 'user',
                    createdAt: u?.createdAt || u?.created_at || new Date().toISOString(),
                    registeredAtIndia: u?.registeredAtIndia || ''
                })),
                total: result.total,
                limit: l,
                offset: o
            };
        }
        catch (error) {
            console.error('[UsersController.listUsers] Fatal Error:', error);
            return {
                success: false,
                message: error.message || 'Failed to list users',
                data: [],
                total: 0
            };
        }
    }
    async makeAdmin(body) {
        if (!body || !body.email || !body.role) {
            return {
                success: false,
                message: 'Email and role are required',
            };
        }
        const allowedRoles = ['admin', 'user', 'staff', 'super_admin', 'agent', 'bank', 'student'];
        if (!allowedRoles.includes(body.role)) {
            return {
                success: false,
                message: `Invalid role. Allowed roles: ${allowedRoles.join(', ')}`,
            };
        }
        const user = await this.usersService.findOne(body.email);
        if (!user) {
            return {
                success: false,
                message: 'User not found',
            };
        }
        const updated = await this.usersService.updateUserRole(body.email, body.role);
        return {
            success: true,
            message: `User ${body.email} role updated to '${body.role}'`,
            user: {
                id: updated.id,
                email: updated.email,
                firstName: updated.firstName,
                lastName: updated.lastName,
                role: updated.role,
            },
        };
    }
    async sendAdminEmail(body) {
        if (!body || !body.subject || !body.content) {
            return { success: false, message: 'Subject and content are required' };
        }
        try {
            if (body.isBulk && body.role) {
                const users = await this.usersService.findAll();
                const filteredUsers = users.data.filter(u => u.role === body.role);
                for (const u of filteredUsers) {
                    await this.emailService.sendMail(u.email, body.subject, `<div style="font-family: sans-serif; padding: 20px;">${body.content}</div>`, body.content);
                }
                return {
                    success: true,
                    message: `Email sent to ${filteredUsers.length} users with role '${body.role}'`
                };
            }
            else if (body.to) {
                await this.emailService.sendMail(body.to, body.subject, `<div style="font-family: sans-serif; padding: 20px;">${body.content}</div>`, body.content);
                return { success: true, message: `Email sent to ${body.to}` };
            }
            else {
                return { success: false, message: 'Recipient email or role is required' };
            }
        }
        catch (error) {
            console.error('Error sending admin email:', error);
            return { success: false, message: 'Failed to send email' };
        }
    }
    async adminCreateUser(body) {
        console.log('=== ADMIN CREATE USER START ===');
        console.log('Request body:', body);
        if (!body || !body.email || !body.role) {
            console.log('Validation failed: missing email or role');
            return { success: false, message: 'Email and role are required' };
        }
        const existing = await this.usersService.findOne(body.email);
        if (existing) {
            return { success: false, message: 'User with this email already exists' };
        }
        try {
            const newUser = await this.usersService.create({
                email: body.email,
                firstName: body.firstName,
                lastName: body.lastName,
                mobile: body.mobile,
                role: body.role,
                password: Math.random().toString(36).slice(-12),
            });
            console.log('New user created:', {
                fullUser: JSON.stringify(newUser),
                hasId: !!newUser?.id,
                id: newUser?.id,
                keys: Object.keys(newUser || {})
            });
            try {
                await this.emailService.sendMail(newUser.email, `Welcome to VidyaLoan - Your ${body.role} Account`, `<div style="font-family: sans-serif; padding: 20px;">
                        <h2>Welcome to the Matrix, ${body.firstName}!</h2>
                        <p>Your account as an <strong>${body.role}</strong> has been created by the administrator.</p>
                        <p>You can now log in using your email: <strong>${body.email}</strong></p>
                        <p>Proceed to the dashboard to complete your profile.</p>
                    </div>`, `Welcome to VidyaLoan! Your ${body.role} account has been created.`);
            }
            catch (emailErr) {
                console.warn('Email sending failed (non-blocking):', emailErr?.message);
            }
            const responseUser = {
                id: newUser?.id,
                email: newUser?.email,
                firstName: newUser?.firstName,
                lastName: newUser?.lastName,
                role: newUser?.role
            };
            console.log('Sending response:', { success: true, user: responseUser });
            const finalResponse = {
                success: true,
                message: 'User created successfully',
                user: responseUser
            };
            console.log('=== ADMIN CREATE USER END ===');
            console.log('Final Response:', JSON.stringify(finalResponse, null, 2));
            return finalResponse;
        }
        catch (error) {
            console.error('=== ERROR IN ADMIN CREATE USER ===');
            console.error('Error creating user by admin:', error);
            const errorResponse = { success: false, message: 'Failed to create user', error: error?.message };
            console.error('Error Response:', JSON.stringify(errorResponse, null, 2));
            return errorResponse;
        }
    }
    async adminUpdateUser(body) {
        if (!body || !body.email) {
            return { success: false, message: 'Email is required' };
        }
        const updated = await this.usersService.updateUserDetails(body.email, body.firstName, body.lastName, body.phoneNumber, body.dateOfBirth);
        return { success: true, message: 'User updated successfully', user: updated };
    }
    async adminUpdateUserStatus(body) {
        if (!body || !body.userId || !body.status) {
            return { success: false, message: 'User ID and status are required' };
        }
        console.log(`[UsersController.adminUpdateUserStatus] Status change request for user ${body.userId} to ${body.status}`);
        const updated = await this.usersService.updateUserStatus(body.userId, body.status, body.rejectionReason);
        return {
            success: true,
            message: 'User status updated successfully',
            user: {
                id: updated.id,
                email: updated.email,
                status: updated.status,
                rejectionReason: updated.rejectionReason
            }
        };
    }
    async getUserById(id) {
        if (!id) {
            return {
                success: false,
                message: 'User ID is required',
            };
        }
        try {
            const user = await this.usersService.findById(id);
            if (!user) {
                return {
                    success: false,
                    message: 'User not found',
                };
            }
            let formattedDOB = '';
            if (user.dateOfBirth) {
                const date = new Date(user.dateOfBirth);
                const day = String(date.getDate()).padStart(2, '0');
                const month = String(date.getMonth() + 1).padStart(2, '0');
                const year = date.getFullYear();
                formattedDOB = `${day}-${month}-${year}`;
            }
            const safeJsonParse = (str) => {
                if (!str)
                    return null;
                try {
                    return typeof str === 'string' ? JSON.parse(str) : str;
                }
                catch (e) {
                    return null;
                }
            };
            return {
                success: true,
                data: {
                    id: user.id,
                    email: user.email,
                    firstName: user.firstName || '',
                    lastName: user.lastName || '',
                    phoneNumber: user.phoneNumber || '',
                    dateOfBirth: formattedDOB,
                    mobile: user.mobile,
                    role: user.role,
                    registeredAtIndia: user.registeredAtIndia || '',
                    panNumber: user.panNumber || '',
                    aadhaarNumber: user.aadhaarNumber || '',
                    fatherName: user.fatherName || '',
                    permanentAddress: user.permanentAddress || '',
                    gender: user.gender || '',
                    documentVerified: user.documentVerified || false,
                    status: user.status || 'pending',
                    rejectionReason: user.rejectionReason || '',
                    goal: user.goal || '',
                    studyDestination: user.studyDestination || '',
                    courseName: user.courseName || '',
                    targetUniversity: user.targetUniversity || '',
                    intakeSeason: user.intakeSeason || '',
                    bachelorsDegree: user.bachelorsDegree || '',
                    gpa: user.gpa || null,
                    workExp: user.workExp || null,
                    entranceTest: user.entranceTest || '',
                    entranceScore: user.entranceScore || '',
                    englishTest: user.englishTest || '',
                    englishScore: user.englishScore || '',
                    budget: user.budget || '',
                    pincode: user.pincode || '',
                    loanAmount: user.loanAmount || '',
                    admitStatus: user.admitStatus || '',
                    passport: safeJsonParse(user.passport),
                    nationality: safeJsonParse(user.nationality),
                    mailingAddress: safeJsonParse(user.mailingAddress),
                    emergencyContact: safeJsonParse(user.emergencyContact),
                    academic: safeJsonParse(user.academic),
                    workExperience: safeJsonParse(user.workExperience),
                    tests: safeJsonParse(user.tests),
                    family: safeJsonParse(user.family),
                    coApplicant: safeJsonParse(user.coApplicant),
                    createdAt: user.createdAt || user.created_at || '',
                },
            };
        }
        catch (error) {
            console.error('Error fetching user details by ID:', error);
            return {
                success: false,
                message: 'Failed to fetch user details',
                error: error?.message,
            };
        }
    }
    async deleteUser(id) {
        if (!id) {
            return { success: false, message: 'User ID is required' };
        }
        try {
            await this.usersService.deleteUser(id);
            return { success: true, message: 'User deleted successfully' };
        }
        catch (error) {
            console.error('Error deleting user by admin:', error);
            return { success: false, message: 'Failed to delete user', error: error?.message };
        }
    }
};
exports.UsersController = UsersController;
__decorate([
    (0, common_1.Post)('profile'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "getProfile", null);
__decorate([
    (0, common_1.Get)('admin/stats'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "getUserStats", null);
__decorate([
    (0, common_1.Get)('admin/list'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Query)('limit')),
    __param(1, (0, common_1.Query)('offset')),
    __param(2, (0, common_1.Query)('search')),
    __param(3, (0, common_1.Query)('role')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "listUsers", null);
__decorate([
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    (0, common_1.Post)('make-admin'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "makeAdmin", null);
__decorate([
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    (0, common_1.Post)('admin/send-email'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "sendAdminEmail", null);
__decorate([
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    (0, common_1.Post)('admin/create'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "adminCreateUser", null);
__decorate([
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    (0, common_1.Post)('admin/update-details'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "adminUpdateUser", null);
__decorate([
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    (0, common_1.Post)('admin/update-status'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "adminUpdateUserStatus", null);
__decorate([
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    (0, common_1.Get)('admin/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "getUserById", null);
__decorate([
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    (0, common_1.Delete)('admin/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "deleteUser", null);
exports.UsersController = UsersController = __decorate([
    (0, common_1.Controller)('users'),
    __metadata("design:paramtypes", [users_service_1.UsersService,
        email_service_1.EmailService])
], UsersController);
//# sourceMappingURL=users.controller.js.map