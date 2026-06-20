"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SlackService = void 0;
const common_1 = require("@nestjs/common");
let SlackService = class SlackService {
    async publishDecisionNotification(bankName, studentName, applicationNumber, decisionType, details) {
        console.log(`[SlackService] Pushing Slack event webhook for ${bankName}...`);
        const blockKitPayload = {
            text: `🏦 VidyaLoans Decision Notification: ${decisionType.toUpperCase()}`,
            blocks: [
                {
                    type: 'header',
                    text: {
                        type: 'plain_text',
                        text: '🏦 VidyaLoans Partner Portal Update',
                        emoji: true
                    }
                },
                {
                    type: 'section',
                    text: {
                        type: 'mrkdwn',
                        text: `*${bankName}* has submitted a *${decisionType.toUpperCase()}* decision for an application.`
                    }
                },
                {
                    type: 'divider'
                },
                {
                    type: 'section',
                    fields: [
                        {
                            type: 'mrkdwn',
                            text: `*Student Name:*\n${studentName}`
                        },
                        {
                            type: 'mrkdwn',
                            text: `*LAN / Application ID:*\n${applicationNumber}`
                        },
                        {
                            type: 'mrkdwn',
                            text: `*Decision:*\n${decisionType}`
                        },
                        {
                            type: 'mrkdwn',
                            text: `*Effective Date:*\n${new Date().toLocaleDateString()}`
                        }
                    ]
                },
                {
                    type: 'section',
                    text: {
                        type: 'mrkdwn',
                        text: `*Decision Notes:*\n${JSON.stringify(details, null, 2)}`
                    }
                },
                {
                    type: 'actions',
                    elements: [
                        {
                            type: 'button',
                            text: {
                                type: 'plain_text',
                                text: 'View Application',
                                emoji: true
                            },
                            value: `app_view_${applicationNumber}`,
                            action_id: 'action_view_application',
                            style: 'primary'
                        },
                        {
                            type: 'button',
                            text: {
                                type: 'plain_text',
                                text: 'Audit Log Details',
                                emoji: true
                            },
                            value: `audit_${applicationNumber}`,
                            action_id: 'action_audit_details'
                        }
                    ]
                }
            ]
        };
        console.log('[SlackService] Built Block Kit Message mockup:', JSON.stringify(blockKitPayload, null, 2));
        return {
            success: true,
            channel: '#loans-pipeline',
            ts: `171620${Math.floor(Math.random() * 900000) + 100000}.000100`,
            mockMessagePayload: blockKitPayload
        };
    }
};
exports.SlackService = SlackService;
exports.SlackService = SlackService = __decorate([
    (0, common_1.Injectable)()
], SlackService);
//# sourceMappingURL=slack.service.js.map