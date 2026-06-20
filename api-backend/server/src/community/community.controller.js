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
exports.CommunityController = void 0;
const common_1 = require("@nestjs/common");
const community_service_1 = require("./community.service");
const admin_guard_1 = require("../auth/admin.guard");
const staff_guard_1 = require("../auth/staff.guard");
const user_guard_1 = require("../auth/user.guard");
const jwt_1 = require("@nestjs/jwt");
let CommunityController = class CommunityController {
    communityService;
    jwtService;
    constructor(communityService, jwtService) {
        this.communityService = communityService;
        this.jwtService = jwtService;
    }
    async getAllMentors(university, country, loanType, category, limit, offset) {
        return this.communityService.getAllMentors({
            university,
            country,
            loanType,
            category,
            limit: limit ? parseInt(limit, 10) : 10,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getFeaturedMentors(limit) {
        return this.communityService.getFeaturedMentors(limit ? parseInt(limit, 10) : 6);
    }
    async getMentorById(id) {
        return this.communityService.getMentorById(id);
    }
    async bookMentorSession(mentorId, body) {
        return this.communityService.bookMentorSession(mentorId, body);
    }
    async applyAsMentor(body) {
        return this.communityService.applyAsMentor(body);
    }
    async getMentorStats() {
        return this.communityService.getMentorStats();
    }
    async getStats() {
        return this.communityService.getCommunityStats();
    }
    async getAllEvents(type, category, featured, limit, offset) {
        return this.communityService.getAllEvents({
            type,
            category,
            featured: featured === 'true' ? true : undefined,
            limit: limit ? parseInt(limit, 10) : 10,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getUpcomingEvents(limit) {
        return this.communityService.getUpcomingEvents(limit ? parseInt(limit, 10) : 5);
    }
    async getPastEvents(limit, offset) {
        return this.communityService.getPastEvents(limit ? parseInt(limit, 10) : 10, offset ? parseInt(offset, 10) : 0);
    }
    async getEventById(id) {
        return this.communityService.getEventById(id);
    }
    async registerForEvent(eventId, body) {
        return this.communityService.registerForEvent(eventId, body);
    }
    async getAllStories(country, category, limit, offset) {
        return this.communityService.getAllStories({
            country,
            category,
            limit: limit ? parseInt(limit, 10) : 10,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getFeaturedStories(limit) {
        return this.communityService.getFeaturedStories(limit ? parseInt(limit, 10) : 6);
    }
    async getStoryById(id) {
        return this.communityService.getStoryById(id);
    }
    async submitStory(body) {
        return this.communityService.submitStory(body);
    }
    async getAllResources(type, category, limit, offset) {
        return this.communityService.getAllResources({
            type,
            category,
            limit: limit ? parseInt(limit, 10) : 10,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getPopularResources(limit) {
        return this.communityService.getPopularResources(limit ? parseInt(limit, 10) : 5);
    }
    async getResourceById(id) {
        return this.communityService.getResourceById(id);
    }
    async trackResourceView(resourceId) {
        return this.communityService.trackResourceView(resourceId);
    }
    async createMentor(body) {
        return this.communityService.createMentor(body);
    }
    async updateMentor(id, body) {
        return this.communityService.updateMentor(id, body);
    }
    async deleteMentor(id) {
        return this.communityService.deleteMentor(id);
    }
    async createEvent(body) {
        return this.communityService.createEvent(body);
    }
    async updateEvent(id, body) {
        return this.communityService.updateEvent(id, body);
    }
    async deleteEvent(id) {
        return this.communityService.deleteEvent(id);
    }
    async createResource(body) {
        return this.communityService.createResource(body);
    }
    async updateResource(id, body) {
        return this.communityService.updateResource(id, body);
    }
    async deleteResource(id) {
        return this.communityService.deleteResource(id);
    }
    async approveMentor(id, body) {
        return this.communityService.approveMentor(id, body.approved, body.reason);
    }
    async createStory(body) {
        return this.communityService.createStory(body);
    }
    async updateStory(id, body) {
        return this.communityService.updateStory(id, body);
    }
    async deleteStory(id) {
        return this.communityService.deleteStory(id);
    }
    async approveStory(id, body) {
        return this.communityService.approveStory(id, body.approved, body.reason);
    }
    async getAllBookings(status, mentorId, limit, offset) {
        return this.communityService.getAllBookings({
            status,
            mentorId,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getAllRegistrations(eventId, limit, offset) {
        return this.communityService.getAllRegistrations({
            eventId,
            limit: limit ? parseInt(limit, 10) : 50,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async getCommunityStats() {
        return this.communityService.getCommunityStats();
    }
    async getAllForumPostsAdmin(category, limit, offset, sort) {
        return this.communityService.getAllForumPostsAdmin({
            category,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
            sort,
        });
    }
    async togglePinForumPost(id, body) {
        return this.communityService.togglePinForumPost(id, body.isPinned);
    }
    async searchForumPosts(q) {
        return this.communityService.searchSimilarPosts(q || '');
    }
    async getForumPostById(id, req) {
        let userId;
        try {
            const authHeader = req.headers.authorization;
            if (authHeader && authHeader.startsWith('Bearer ')) {
                const token = authHeader.split(' ')[1];
                const decoded = this.jwtService.decode(token);
                if (decoded && decoded.id) {
                    userId = decoded.id;
                }
            }
        }
        catch (e) {
        }
        return this.communityService.getForumPostById(id, userId);
    }
    async getForumPosts(category, tag, limit, offset, sort, req) {
        let userId;
        try {
            if (req.headers.authorization) {
                const token = req.headers.authorization.split(' ')[1];
                const decoded = this.jwtService.decode(token);
                userId = decoded?.id;
            }
        }
        catch (e) { }
        return this.communityService.getForumPosts({
            category,
            tag,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
            sort
        }, userId);
    }
    async getPostsAlias(topic, page, req) {
        const category = topic;
        const offset = page ? (parseInt(page, 10) - 1) * 20 : 0;
        let userId;
        try {
            if (req?.headers?.authorization) {
                const token = req.headers.authorization.split(' ')[1];
                const decoded = this.jwtService.decode(token);
                userId = decoded?.id;
            }
        }
        catch (e) { }
        return this.communityService.getForumPosts({ category, limit: 20, offset }, userId);
    }
    async getHubs() {
        return this.communityService.getHubs();
    }
    async getPostByIdAlias(id, req) {
        let userId;
        try {
            const authHeader = req.headers.authorization;
            if (authHeader && authHeader.startsWith('Bearer ')) {
                const token = authHeader.split(' ')[1];
                const decoded = this.jwtService.decode(token);
                if (decoded && decoded.id) {
                    userId = decoded.id;
                }
            }
        }
        catch (e) { }
        return this.communityService.getForumPostById(id, userId);
    }
    async createPostAlias(req, body) {
        const allowedCategories = [
            'Education Loans',
            'Universities',
            'Courses',
            'Exams',
            'GRE / GMAT',
            'IELTS / TOEFL',
            'Scholarship',
            'Visa & Immigration',
            'Career & Jobs',
            'General'
        ];
        const providedCategory = (body && body.category) ? String(body.category).trim() : '';
        const isAllowed = allowedCategories.some(c => c.toLowerCase() === providedCategory.toLowerCase());
        if (!providedCategory || !isAllowed) {
            throw new common_1.HttpException({
                success: false,
                message: 'Category not allowed. Please choose one of: ' + allowedCategories.join(', '),
                allowedCategories,
            }, common_1.HttpStatus.BAD_REQUEST);
        }
        const force = body && body.force === true;
        if (!force) {
            try {
                const dup = await this.communityService.checkDuplicateQuestion({
                    title: body.title || '',
                    content: body.content || '',
                    category: body.category || 'General'
                });
                if (dup && dup.isDuplicate) {
                    throw new common_1.HttpException({
                        success: false,
                        message: 'Similar questions found',
                        isDuplicate: true,
                        similarQuestions: dup.similarQuestions || []
                    }, common_1.HttpStatus.CONFLICT);
                }
            }
            catch (err) {
                if (err instanceof common_1.HttpException)
                    throw err;
                console.error('[CommunityController] duplicate check failed, continuing to create post', err);
            }
        }
        return this.communityService.createForumPost(req.user.id, body);
    }
    async createForumPostRoute(req, body) {
        return this.createPostAlias(req, body);
    }
    async createForumComment(req, id, body) {
        return this.communityService.createForumComment(req.user.id, id, body.content, body.parentId);
    }
    async likeForumComment(req, id) {
        return this.communityService.likeForumComment(req.user.id, id);
    }
    async likeForumPost(req, id) {
        return this.communityService.likeForumPost(req.user.id, id);
    }
    async shareForumPost(id) {
        return this.communityService.shareForumPost(id);
    }
    async deleteForumPost(req, id) {
        const post = await this.communityService.getForumPostById(id, req.user.id);
        const isAuthor = post?.data?.authorId === req.user.id;
        const isAdmin = req.user.role === 'admin' || req.user.role === 'super_admin';
        if (!isAuthor && !isAdmin) {
            throw new common_1.HttpException('You can only delete your own posts', common_1.HttpStatus.FORBIDDEN);
        }
        return this.communityService.deleteForumPost(id);
    }
    async deleteForumComment(req, id) {
        return this.communityService.deleteForumComment(req.user.id, req.user.role, id);
    }
    async checkDuplicateQuestion(body) {
        const result = await this.communityService.checkDuplicateQuestion(body);
        return {
            success: true,
            ...result
        };
    }
    async requestMentorOTP(body) {
        return this.communityService.requestMentorOTP(body.email);
    }
    async verifyMentorOTP(body) {
        return this.communityService.verifyMentorOTP(body.email, body.otp);
    }
    async getMentorProfile(mentorId) {
        return this.communityService.getMentorProfile(mentorId);
    }
    async getMentorBookings(mentorId, status, limit, offset) {
        return this.communityService.getMentorBookings(mentorId, {
            status,
            limit: limit ? parseInt(limit, 10) : 20,
            offset: offset ? parseInt(offset, 10) : 0,
        });
    }
    async updateBookingStatus(mentorId, bookingId, body) {
        return this.communityService.updateBookingStatus(mentorId, bookingId, body.status);
    }
    async updateMentorProfile(mentorId, body) {
        return this.communityService.updateMentorProfile(mentorId, body);
    }
};
exports.CommunityController = CommunityController;
__decorate([
    (0, common_1.Get)('mentors'),
    __param(0, (0, common_1.Query)('university')),
    __param(1, (0, common_1.Query)('country')),
    __param(2, (0, common_1.Query)('loanType')),
    __param(3, (0, common_1.Query)('category')),
    __param(4, (0, common_1.Query)('limit')),
    __param(5, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getAllMentors", null);
__decorate([
    (0, common_1.Get)('mentors/featured'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getFeaturedMentors", null);
__decorate([
    (0, common_1.Get)('mentors/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getMentorById", null);
__decorate([
    (0, common_1.Post)('mentors/:id/book'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "bookMentorSession", null);
__decorate([
    (0, common_1.Post)('mentors/apply'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "applyAsMentor", null);
__decorate([
    (0, common_1.Get)('mentors/stats'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getMentorStats", null);
__decorate([
    (0, common_1.Get)('stats'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getStats", null);
__decorate([
    (0, common_1.Get)('events'),
    __param(0, (0, common_1.Query)('type')),
    __param(1, (0, common_1.Query)('category')),
    __param(2, (0, common_1.Query)('featured')),
    __param(3, (0, common_1.Query)('limit')),
    __param(4, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getAllEvents", null);
__decorate([
    (0, common_1.Get)('events/upcoming'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getUpcomingEvents", null);
__decorate([
    (0, common_1.Get)('events/past'),
    __param(0, (0, common_1.Query)('limit')),
    __param(1, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getPastEvents", null);
__decorate([
    (0, common_1.Get)('events/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getEventById", null);
__decorate([
    (0, common_1.Post)('events/:id/register'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "registerForEvent", null);
__decorate([
    (0, common_1.Get)('stories'),
    __param(0, (0, common_1.Query)('country')),
    __param(1, (0, common_1.Query)('category')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getAllStories", null);
__decorate([
    (0, common_1.Get)('stories/featured'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getFeaturedStories", null);
__decorate([
    (0, common_1.Get)('stories/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getStoryById", null);
__decorate([
    (0, common_1.Post)('stories/submit'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "submitStory", null);
__decorate([
    (0, common_1.Get)('resources'),
    __param(0, (0, common_1.Query)('type')),
    __param(1, (0, common_1.Query)('category')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getAllResources", null);
__decorate([
    (0, common_1.Get)('resources/popular'),
    __param(0, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getPopularResources", null);
__decorate([
    (0, common_1.Get)('resources/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getResourceById", null);
__decorate([
    (0, common_1.Post)('resources/:id/track'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "trackResourceView", null);
__decorate([
    (0, common_1.Post)('admin/mentors'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createMentor", null);
__decorate([
    (0, common_1.Put)('admin/mentors/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "updateMentor", null);
__decorate([
    (0, common_1.Delete)('admin/mentors/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "deleteMentor", null);
__decorate([
    (0, common_1.Post)('admin/events'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createEvent", null);
__decorate([
    (0, common_1.Put)('admin/events/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "updateEvent", null);
__decorate([
    (0, common_1.Delete)('admin/events/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "deleteEvent", null);
__decorate([
    (0, common_1.Post)('admin/resources'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createResource", null);
__decorate([
    (0, common_1.Put)('admin/resources/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "updateResource", null);
__decorate([
    (0, common_1.Delete)('admin/resources/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "deleteResource", null);
__decorate([
    (0, common_1.Put)('admin/mentors/:id/approve'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "approveMentor", null);
__decorate([
    (0, common_1.Post)('admin/stories'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createStory", null);
__decorate([
    (0, common_1.Put)('admin/stories/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "updateStory", null);
__decorate([
    (0, common_1.Delete)('admin/stories/:id'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "deleteStory", null);
__decorate([
    (0, common_1.Put)('admin/stories/:id/approve'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "approveStory", null);
__decorate([
    (0, common_1.Get)('admin/bookings'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Query)('status')),
    __param(1, (0, common_1.Query)('mentorId')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getAllBookings", null);
__decorate([
    (0, common_1.Get)('admin/registrations'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Query)('eventId')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getAllRegistrations", null);
__decorate([
    (0, common_1.Get)('admin/stats'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getCommunityStats", null);
__decorate([
    (0, common_1.Get)('admin/forum/posts'),
    (0, common_1.UseGuards)(staff_guard_1.StaffGuard),
    __param(0, (0, common_1.Query)('category')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('offset')),
    __param(3, (0, common_1.Query)('sort')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getAllForumPostsAdmin", null);
__decorate([
    (0, common_1.Put)('admin/forum/posts/:id/pin'),
    (0, common_1.UseGuards)(admin_guard_1.AdminGuard),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "togglePinForumPost", null);
__decorate([
    (0, common_1.Get)('forum/search'),
    __param(0, (0, common_1.Query)('q')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "searchForumPosts", null);
__decorate([
    (0, common_1.Get)('forum/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getForumPostById", null);
__decorate([
    (0, common_1.Get)('forum'),
    __param(0, (0, common_1.Query)('category')),
    __param(1, (0, common_1.Query)('tag')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __param(4, (0, common_1.Query)('sort')),
    __param(5, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String, String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getForumPosts", null);
__decorate([
    (0, common_1.Get)('posts'),
    __param(0, (0, common_1.Query)('topic')),
    __param(1, (0, common_1.Query)('page')),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getPostsAlias", null);
__decorate([
    (0, common_1.Get)('hubs'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getHubs", null);
__decorate([
    (0, common_1.Get)('posts/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getPostByIdAlias", null);
__decorate([
    (0, common_1.Post)('posts'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createPostAlias", null);
__decorate([
    (0, common_1.Post)('forum'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createForumPostRoute", null);
__decorate([
    (0, common_1.Post)('forum/:id/comment'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "createForumComment", null);
__decorate([
    (0, common_1.Post)('forum/comments/:id/like'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "likeForumComment", null);
__decorate([
    (0, common_1.Post)('forum/:id/like'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "likeForumPost", null);
__decorate([
    (0, common_1.Post)('forum/:id/share'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "shareForumPost", null);
__decorate([
    (0, common_1.Delete)('forum/:id'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "deleteForumPost", null);
__decorate([
    (0, common_1.Delete)('forum/comments/:id'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "deleteForumComment", null);
__decorate([
    (0, common_1.Post)('forum/check-duplicate'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "checkDuplicateQuestion", null);
__decorate([
    (0, common_1.Post)('mentor/request-otp'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "requestMentorOTP", null);
__decorate([
    (0, common_1.Post)('mentor/verify-otp'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "verifyMentorOTP", null);
__decorate([
    (0, common_1.Get)('mentor/profile/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getMentorProfile", null);
__decorate([
    (0, common_1.Get)('mentor/:id/bookings'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Query)('status')),
    __param(2, (0, common_1.Query)('limit')),
    __param(3, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "getMentorBookings", null);
__decorate([
    (0, common_1.Put)('mentor/:mentorId/bookings/:bookingId'),
    __param(0, (0, common_1.Param)('mentorId')),
    __param(1, (0, common_1.Param)('bookingId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "updateBookingStatus", null);
__decorate([
    (0, common_1.Put)('mentor/:id/profile'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], CommunityController.prototype, "updateMentorProfile", null);
exports.CommunityController = CommunityController = __decorate([
    (0, common_1.Controller)('community'),
    __metadata("design:paramtypes", [community_service_1.CommunityService,
        jwt_1.JwtService])
], CommunityController);
//# sourceMappingURL=community.controller.js.map