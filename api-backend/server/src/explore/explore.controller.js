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
exports.ExploreController = void 0;
const common_1 = require("@nestjs/common");
const explore_service_1 = require("./explore.service");
const user_guard_1 = require("../auth/user.guard");
const jwt_1 = require("@nestjs/jwt");
let ExploreController = class ExploreController {
    exploreService;
    jwtService;
    constructor(exploreService, jwtService) {
        this.exploreService = exploreService;
        this.jwtService = jwtService;
    }
    async getAllHubs() {
        return this.exploreService.getAllHubs();
    }
    async getHubData(topic) {
        return this.exploreService.getHubData(topic);
    }
    async getHubPosts(topic, req, sort) {
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
        return this.exploreService.getHubPosts(topic, sort, userId);
    }
    async createHubPost(req, topic, body) {
        console.log(`[ExploreController] createHubPost called for topic: ${topic}`);
        console.log(`[ExploreController] User: ${req.user?.id}`);
        console.log(`[ExploreController] Body:`, body);
        return this.exploreService.createHubPost(req.user.id, topic, body);
    }
};
exports.ExploreController = ExploreController;
__decorate([
    (0, common_1.Get)('hubs'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ExploreController.prototype, "getAllHubs", null);
__decorate([
    (0, common_1.Get)('hub/:topic'),
    __param(0, (0, common_1.Param)('topic')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], ExploreController.prototype, "getHubData", null);
__decorate([
    (0, common_1.Get)('hub/:topic/forum'),
    __param(0, (0, common_1.Param)('topic')),
    __param(1, (0, common_1.Request)()),
    __param(2, (0, common_1.Query)('sort')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, String]),
    __metadata("design:returntype", Promise)
], ExploreController.prototype, "getHubPosts", null);
__decorate([
    (0, common_1.Post)('hub/:topic/forum'),
    (0, common_1.UseGuards)(user_guard_1.UserGuard),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('topic')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, Object]),
    __metadata("design:returntype", Promise)
], ExploreController.prototype, "createHubPost", null);
exports.ExploreController = ExploreController = __decorate([
    (0, common_1.Controller)('community/explore'),
    __metadata("design:paramtypes", [explore_service_1.ExploreService,
        jwt_1.JwtService])
], ExploreController);
//# sourceMappingURL=explore.controller.js.map