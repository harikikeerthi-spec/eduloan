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
exports.AuthController = void 0;
const common_1 = require("@nestjs/common");
const auth_service_1 = require("./auth.service");
const users_service_1 = require("../users/users.service");
const referral_service_1 = require("../referral/referral.service");
let AuthController = class AuthController {
    authService;
    usersService;
    referralService;
    constructor(authService, usersService, referralService) {
        this.authService = authService;
        this.usersService = usersService;
        this.referralService = referralService;
    }
    async checkUserExists(email) {
        return this.authService.checkUserExists(email);
    }
    async sendOtp(body) {
        if (!body || !body.email) {
            return {
                success: false,
                message: 'Email address is required',
            };
        }
        return this.authService.sendOtpUnified(body.email);
    }
    async verifyOtp(body) {
        if (!body || !body.email || !body.otp) {
            return {
                success: false,
                message: 'Email and OTP are both required',
            };
        }
        const result = await this.authService.verifyOtpUnified(body.email, body.otp);
        if (result.success && !result.userExists && body.referralCode) {
            try {
                await this.referralService.recordReferral(body.referralCode, body.email, result.userId);
            }
            catch (error) {
                console.error('Failed to record referral during signup:', error);
            }
        }
        return result;
    }
    async firebaseLogin(body) {
        if (!body || !body.idToken) {
            return {
                success: false,
                message: 'Firebase ID Token is required',
            };
        }
        return this.authService.authenticateFirebaseUser(body.idToken);
    }
    async refreshToken(body) {
        if (!body || !body.refresh_token) {
            return {
                success: false,
                message: 'Refresh token is required',
            };
        }
        return this.authService.refreshTokens(body.refresh_token);
    }
    async logout(body) {
        if (!body || !body.email) {
            return {
                success: false,
                message: 'Email is required',
            };
        }
        return this.authService.logout(body.email);
    }
    async getUserDashboard(body) {
        if (!body || !body.email) {
            return {
                success: false,
                message: 'Email is required to fetch dashboard',
            };
        }
        try {
            return await this.authService.getUserDashboard(body.email);
        }
        catch (error) {
            console.error('[AuthController.getUserDashboard] Fatal Error:', error);
            return {
                success: false,
                message: 'Internal server error occurred while fetching dashboard',
                error: error.message
            };
        }
    }
    async getDashboardData(body) {
        if (!body || !body.userId) {
            return {
                success: false,
                message: 'User ID is required',
            };
        }
        try {
            const data = await this.usersService.getUserDashboardData(body.userId);
            return {
                success: true,
                data,
            };
        }
        catch (error) {
            console.error('getDashboardData error:', error);
            return {
                success: false,
                message: `Failed to fetch dashboard data: ${error.message}`,
            };
        }
    }
    async updateUserDetails(body) {
        if (!body || !body.email) {
            return {
                success: false,
                message: 'Email is required',
            };
        }
        return this.authService.updateUserDetails(body.email, body.firstName, body.lastName, body.phoneNumber, body.dateOfBirth, body.profileImage);
    }
    async createApplication(body) {
        if (!body || !body.userId) {
            return {
                success: false,
                message: 'User ID is required',
            };
        }
        const amountVal = typeof body.amount === 'string' ? parseFloat(body.amount) : body.amount;
        if (isNaN(amountVal)) {
            return {
                success: false,
                message: 'Valid loan amount is required',
            };
        }
        try {
            const application = await this.usersService.createLoanApplication(body.userId, {
                bank: body.bank,
                loanType: body.loanType,
                amount: amountVal,
                purpose: body.purpose,
                courseType: body.courseType,
                courseName: body.courseName,
                program: body.program,
                programFocus: body.programFocus,
                country: body.country,
                university: body.university,
                universityName: body.universityName,
                targetUniversity: body.targetUniversity,
                annualFee: body.annualFee,
                livingCost: body.livingCost,
                coApplicant: body.coApplicant,
                income: body.income,
                collateral: body.collateral,
                firstName: body.firstName,
                lastName: body.lastName,
                email: body.email,
                phone: body.phone,
                dateOfBirth: body.dateOfBirth,
                address: body.address,
                notes: body.notes,
            });
            return {
                success: true,
                application,
            };
        }
        catch (error) {
            console.error('Create application error:', error);
            throw error;
        }
    }
    async getApplications(body) {
        if (!body || !body.userId) {
            return {
                success: false,
                message: 'User ID is required',
            };
        }
        try {
            const applications = await this.usersService.getUserApplications(body.userId);
            return {
                success: true,
                applications,
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Failed to fetch applications',
            };
        }
    }
    async updateApplication(id, body) {
        if (!body || !body.status) {
            return {
                success: false,
                message: 'Status is required',
            };
        }
        try {
            const application = await this.usersService.updateLoanApplicationStatus(id, body.status);
            return {
                success: true,
                application,
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Failed to update application',
            };
        }
    }
    async deleteApplication(id) {
        try {
            await this.usersService.deleteLoanApplication(id);
            return {
                success: true,
                message: 'Application deleted successfully',
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Failed to delete application',
            };
        }
    }
    async uploadDocument(body) {
        if (!body || !body.userId || !body.docType) {
            return {
                success: false,
                message: 'User ID and Document Type are required',
            };
        }
        try {
            const document = await this.usersService.upsertUserDocument(body.userId, body.docType, {
                uploaded: body.uploaded,
                filePath: body.filePath,
                status: body.uploaded ? 'uploaded' : 'pending',
            });
            return {
                success: true,
                document,
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Failed to upload document',
            };
        }
    }
    async getDocuments(body) {
        if (!body || !body.userId) {
            return {
                success: false,
                message: 'User ID is required',
            };
        }
        try {
            const documents = await this.usersService.getUserDocuments(body.userId);
            return {
                success: true,
                documents,
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Failed to fetch documents',
            };
        }
    }
    async deleteDocument(userId, docType) {
        try {
            await this.usersService.deleteUserDocument(userId, docType);
            return {
                success: true,
                message: 'Document deleted successfully',
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Failed to delete document',
            };
        }
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Get)('check-user/:email'),
    __param(0, (0, common_1.Param)('email')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "checkUserExists", null);
__decorate([
    (0, common_1.Post)('send-otp'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "sendOtp", null);
__decorate([
    (0, common_1.Post)('verify-otp'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyOtp", null);
__decorate([
    (0, common_1.Post)('firebase'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "firebaseLogin", null);
__decorate([
    (0, common_1.Post)('refresh'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "refreshToken", null);
__decorate([
    (0, common_1.Post)('logout'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "logout", null);
__decorate([
    (0, common_1.Post)('dashboard'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getUserDashboard", null);
__decorate([
    (0, common_1.Post)('dashboard-data'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getDashboardData", null);
__decorate([
    (0, common_1.Post)('update-details'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "updateUserDetails", null);
__decorate([
    (0, common_1.Post)('create-application'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "createApplication", null);
__decorate([
    (0, common_1.Post)('applications'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getApplications", null);
__decorate([
    (0, common_1.Post)('update-application/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "updateApplication", null);
__decorate([
    (0, common_1.Delete)('application/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "deleteApplication", null);
__decorate([
    (0, common_1.Post)('upload-document'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "uploadDocument", null);
__decorate([
    (0, common_1.Post)('documents'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getDocuments", null);
__decorate([
    (0, common_1.Delete)('document/:userId/:docType'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Param)('docType')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "deleteDocument", null);
exports.AuthController = AuthController = __decorate([
    (0, common_1.Controller)('auth'),
    __metadata("design:paramtypes", [auth_service_1.AuthService,
        users_service_1.UsersService,
        referral_service_1.ReferralService])
], AuthController);
//# sourceMappingURL=auth.controller.js.map