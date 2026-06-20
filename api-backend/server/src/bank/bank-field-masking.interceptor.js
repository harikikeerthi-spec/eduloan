"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BankFieldMaskingInterceptor = void 0;
const common_1 = require("@nestjs/common");
const operators_1 = require("rxjs/operators");
let BankFieldMaskingInterceptor = class BankFieldMaskingInterceptor {
    intercept(context, next) {
        const request = context.switchToHttp().getRequest();
        const user = request.user;
        const role = user?.role || 'anonymous';
        return next.handle().pipe((0, operators_1.map)((data) => {
            return this.maskData(data, role);
        }));
    }
    maskData(data, role) {
        if (role === 'admin' || role === 'super_admin') {
            return data;
        }
        return this.maskObject(data, role);
    }
    maskObject(obj, role) {
        if (obj === null || obj === undefined)
            return obj;
        if (Array.isArray(obj)) {
            return obj.map((item) => this.maskObject(item, role));
        }
        if (typeof obj === 'object') {
            if (obj instanceof Date) {
                return obj;
            }
            const keysToMask = this.getMaskKeys(role);
            const newObj = {};
            for (const key of Object.keys(obj)) {
                if (keysToMask.includes(key)) {
                    continue;
                }
                newObj[key] = this.maskObject(obj[key], role);
            }
            return newObj;
        }
        return obj;
    }
    getMaskKeys(role) {
        const roleNormalized = role.toLowerCase();
        if (roleNormalized === 'staff') {
            return [
                'disbursements',
                'utrNumber',
                'agentCommission',
                'referralFee',
                'creditScore',
                'fileLoggedAt',
                'sanctionConditionsInternal',
            ];
        }
        if (roleNormalized === 'bank' || roleNormalized === 'partner_bank') {
            return [
                'disbursements',
                'agentCommission',
                'referralFee',
                'staffMetrics',
                'revenueData',
            ];
        }
        return [];
    }
};
exports.BankFieldMaskingInterceptor = BankFieldMaskingInterceptor;
exports.BankFieldMaskingInterceptor = BankFieldMaskingInterceptor = __decorate([
    (0, common_1.Injectable)()
], BankFieldMaskingInterceptor);
//# sourceMappingURL=bank-field-masking.interceptor.js.map