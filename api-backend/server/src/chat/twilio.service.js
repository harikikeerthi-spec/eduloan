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
var TwilioService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.TwilioService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const twilio_1 = require("twilio");
let TwilioService = TwilioService_1 = class TwilioService {
    configService;
    logger = new common_1.Logger(TwilioService_1.name);
    client;
    constructor(configService) {
        this.configService = configService;
        const accountSid = this.configService.get('TWILIO_ACCOUNT_SID');
        const authToken = this.configService.get('TWILIO_AUTH_TOKEN');
        if (accountSid && authToken && accountSid !== 'AC_mock_sid') {
            try {
                this.client = new twilio_1.Twilio(accountSid, authToken);
            }
            catch (e) {
                this.logger.warn('Failed to initialize real Twilio client. Using mock.');
            }
        }
    }
    async sendWhatsAppMessage(to, body) {
        const from = this.configService.get('TWILIO_WHATSAPP_NUMBER') || 'whatsapp:+14155238886';
        let cleanTo = to.replace('whatsapp:', '').trim().replace(/\D/g, '');
        if (cleanTo.length === 10) {
            cleanTo = `+91${cleanTo}`;
        }
        else {
            cleanTo = `+${cleanTo}`;
        }
        const formattedTo = `whatsapp:${cleanTo}`;
        if (!this.client) {
            this.logger.log(`[MOCK TWILIO] Sending message to ${formattedTo}: ${body}`);
            return { sid: `mock_sid_${Date.now()}`, status: 'sent' };
        }
        try {
            const message = await this.client.messages.create({
                body,
                from,
                to: formattedTo,
            });
            this.logger.log(`WhatsApp message sent to ${formattedTo}. SID: ${message.sid}`);
            return message;
        }
        catch (error) {
            if (error.code === 20003) {
                this.logger.warn(`[TWILIO AUTH ERROR] Could not send message to ${formattedTo}. Please check your SID/Token in .env. Simulator will still receive this.`);
            }
            else {
                this.logger.error(`Failed to send WhatsApp message to ${formattedTo}: ${error.message}`);
            }
            throw error;
        }
    }
};
exports.TwilioService = TwilioService;
exports.TwilioService = TwilioService = TwilioService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], TwilioService);
//# sourceMappingURL=twilio.service.js.map