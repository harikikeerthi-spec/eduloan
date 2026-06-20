"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatModule = void 0;
const common_1 = require("@nestjs/common");
const chat_service_1 = require("./chat.service");
const twilio_service_1 = require("./twilio.service");
const chat_gateway_1 = require("./chat.gateway");
const whatsapp_controller_1 = require("./whatsapp.controller");
const chat_controller_1 = require("./chat.controller");
const multiparty_chat_service_1 = require("./multiparty-chat.service");
const multiparty_chat_controller_1 = require("./multiparty-chat.controller");
const student_notification_service_1 = require("./student-notification.service");
const email_service_1 = require("./email.service");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const users_module_1 = require("../users/users.module");
const event_emitter_1 = require("@nestjs/event-emitter");
const document_module_1 = require("../document/document.module");
let ChatModule = class ChatModule {
};
exports.ChatModule = ChatModule;
exports.ChatModule = ChatModule = __decorate([
    (0, common_1.Module)({
        imports: [
            event_emitter_1.EventEmitterModule,
            users_module_1.UsersModule,
            document_module_1.DocumentModule,
            config_1.ConfigModule,
            jwt_1.JwtModule.registerAsync({
                imports: [config_1.ConfigModule],
                useFactory: async (configService) => ({
                    secret: configService.get('JWT_SECRET'),
                }),
                inject: [config_1.ConfigService],
            })
        ],
        controllers: [whatsapp_controller_1.WhatsappController, chat_controller_1.ChatController, multiparty_chat_controller_1.MultiPartyChatController],
        providers: [chat_service_1.ChatService, twilio_service_1.TwilioService, chat_gateway_1.ChatGateway, multiparty_chat_service_1.MultiPartyChatService, email_service_1.EmailService, student_notification_service_1.StudentNotificationService],
        exports: [chat_service_1.ChatService, multiparty_chat_service_1.MultiPartyChatService, email_service_1.EmailService, student_notification_service_1.StudentNotificationService]
    })
], ChatModule);
//# sourceMappingURL=chat.module.js.map