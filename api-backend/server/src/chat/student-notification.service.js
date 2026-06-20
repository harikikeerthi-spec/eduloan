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
var StudentNotificationService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.StudentNotificationService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const twilio_1 = require("twilio");
let StudentNotificationService = StudentNotificationService_1 = class StudentNotificationService {
    configService;
    logger = new common_1.Logger(StudentNotificationService_1.name);
    client = null;
    constructor(configService) {
        this.configService = configService;
        const accountSid = this.configService.get('TWILIO_ACCOUNT_SID');
        const authToken = this.configService.get('TWILIO_AUTH_TOKEN');
        if (accountSid && authToken && !accountSid.startsWith('your_')) {
            try {
                this.client = new twilio_1.Twilio(accountSid, authToken);
                this.logger.log('Twilio client initialised (live mode).');
            }
            catch (e) {
                this.logger.warn('Twilio client init failed — mock mode active.');
            }
        }
        else {
            this.logger.warn('Twilio credentials not set — mock mode active.');
        }
    }
    async sendStudentNotification(student) {
        const { name, mobile, whatsapp_consent } = student;
        const safeBody = `Hi ${name}, you have a new update from VidyaLoans staff. ` +
            `Login to your portal to view and reply.`;
        if (whatsapp_consent) {
            try {
                return await this.sendWhatsApp(mobile, safeBody);
            }
            catch (err) {
                this.logger.warn(`WhatsApp failed for ${mobile}: ${err.message}. Falling back to SMS.`);
                return await this.sendSMS(mobile, safeBody);
            }
        }
        return await this.sendSMS(mobile, safeBody);
    }
    async sendWhatsApp(mobile, body) {
        const from = this.configService.get('TWILIO_WHATSAPP_NUMBER') ||
            'whatsapp:+14155238886';
        const to = `whatsapp:+91${mobile}`;
        if (!this.client) {
            this.logger.log(`[MOCK] WhatsApp → ${to}: ${body}`);
            return { channel: 'mock', sid: `mock_wa_${Date.now()}`, status: 'mocked' };
        }
        const result = await this.client.messages.create({ from, to, body });
        this.logger.log(`WhatsApp sent to ${to}. SID: ${result.sid}, Status: ${result.status}`);
        return { channel: 'whatsapp', sid: result.sid, status: result.status };
    }
    async sendSMS(mobile, body) {
        const from = this.configService.get('TWILIO_SMS_NUMBER');
        const to = `+91${mobile}`;
        if (!this.client || !from) {
            this.logger.log(`[MOCK] SMS → ${to}: ${body}`);
            return {
                channel: 'mock',
                sid: `mock_sms_${Date.now()}`,
                status: 'mocked',
            };
        }
        const result = await this.client.messages.create({ from, to, body });
        this.logger.log(`SMS sent to ${to}. SID: ${result.sid}`);
        return { channel: 'sms', sid: result.sid, status: result.status };
    }
};
exports.StudentNotificationService = StudentNotificationService;
exports.StudentNotificationService = StudentNotificationService = StudentNotificationService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], StudentNotificationService);
//# sourceMappingURL=student-notification.service.js.map