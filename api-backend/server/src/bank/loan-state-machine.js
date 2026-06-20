"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LoanStateMachine = void 0;
const common_1 = require("@nestjs/common");
class LoanStateMachine {
    static transitions = [
        {
            from: ['pending'],
            to: 'docs_received',
            allowedRoles: ['staff', 'admin', 'super_admin']
        },
        {
            from: ['docs_received', 'pending'],
            to: 'staff_verified',
            allowedRoles: ['staff', 'admin', 'super_admin']
        },
        {
            from: ['staff_verified'],
            to: 'submitted_to_bank',
            allowedRoles: ['staff', 'admin', 'super_admin']
        },
        {
            from: ['submitted_to_bank'],
            to: 'file_logged',
            allowedRoles: ['bank', 'partner_bank', 'staff', 'admin', 'super_admin']
        },
        {
            from: ['file_logged', 'submitted_to_bank'],
            to: 'under_bank_review',
            allowedRoles: ['bank', 'partner_bank', 'staff', 'admin', 'super_admin']
        },
        {
            from: ['under_bank_review', 'file_logged'],
            to: 'query_raised',
            allowedRoles: ['bank', 'partner_bank', 'staff', 'admin', 'super_admin']
        },
        {
            from: ['query_raised'],
            to: 'under_bank_review',
            allowedRoles: ['staff', 'admin', 'super_admin', 'bank', 'partner_bank']
        },
        {
            from: ['under_bank_review', 'file_logged', 'query_raised'],
            to: 'approved',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['under_bank_review', 'file_logged', 'query_raised', 'approved'],
            to: 'sanctioned',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['under_bank_review', 'file_logged', 'query_raised'],
            to: 'conditional_sanction',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['under_bank_review', 'file_logged', 'query_raised'],
            to: 'partial_sanction',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['under_bank_review', 'file_logged', 'query_raised'],
            to: 'counter_offer',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['conditional_sanction', 'partial_sanction', 'counter_offer'],
            to: 'sanctioned',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['under_bank_review', 'file_logged', 'query_raised', 'conditional_sanction', 'partial_sanction', 'counter_offer'],
            to: 'rejected',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['approved', 'sanctioned', 'conditional_sanction', 'partial_sanction', 'counter_offer'],
            to: 'disbursement_confirmed',
            allowedRoles: ['bank', 'partner_bank', 'admin', 'super_admin']
        },
        {
            from: ['disbursement_confirmed'],
            to: 'closed',
            allowedRoles: ['admin', 'super_admin', 'staff']
        },
        {
            from: ['approved', 'sanctioned', 'conditional_sanction', 'partial_sanction', 'counter_offer', 'under_bank_review', 'file_logged'],
            to: 'expired',
            allowedRoles: ['system', 'admin', 'super_admin']
        }
    ];
    static validateTransition(currentStatus, targetStatus, userRole) {
        const fromStatus = (currentStatus?.toLowerCase() || 'pending');
        const toStatus = (targetStatus?.toLowerCase());
        const role = userRole?.toLowerCase();
        const transition = this.transitions.find(t => t.to.toLowerCase() === toStatus && t.from.includes(fromStatus));
        if (!transition) {
            throw new common_1.BadRequestException(`Invalid lifecycle transition: Cannot move loan application from "${fromStatus.toUpperCase()}" to "${toStatus.toUpperCase()}"`);
        }
        if (role === 'super_admin' || role === 'system') {
            return;
        }
        const isRoleAllowed = transition.allowedRoles.some(r => r.toLowerCase() === role || (r === 'partner_bank' && role === 'bank'));
        if (!isRoleAllowed) {
            throw new common_1.BadRequestException(`Unauthorized action: Role "${userRole}" is not permitted to advance status to "${targetStatus.toUpperCase()}"`);
        }
    }
    static getProgressByStatus(status) {
        const s = status?.toLowerCase();
        switch (s) {
            case 'pending': return 10;
            case 'docs_received': return 25;
            case 'staff_verified': return 40;
            case 'submitted_to_bank': return 50;
            case 'file_logged': return 60;
            case 'under_bank_review': return 70;
            case 'query_raised': return 75;
            case 'conditional_sanction': return 80;
            case 'partial_sanction': return 80;
            case 'counter_offer': return 80;
            case 'approved': return 85;
            case 'sanctioned': return 90;
            case 'disbursement_confirmed': return 95;
            case 'closed': return 100;
            default: return 10;
        }
    }
    static getStageByStatus(status) {
        const s = status?.toLowerCase();
        if (['pending', 'docs_received'].includes(s))
            return 'Pre-login';
        if (['staff_verified', 'submitted_to_bank'].includes(s))
            return 'Submitted';
        if (['file_logged', 'under_bank_review', 'query_raised'].includes(s))
            return 'Verification';
        if (['conditional_sanction', 'partial_sanction', 'counter_offer', 'approved', 'sanctioned'].includes(s))
            return 'Sanctioned';
        if (['disbursement_confirmed', 'closed'].includes(s))
            return 'Disbursed';
        return 'Pre-login';
    }
    static getAllowedTransitions(currentStatus, userRole) {
        const fromStatus = (currentStatus?.toLowerCase() || 'pending');
        const role = userRole?.toLowerCase();
        const isSuperAdminOrSystem = role === 'super_admin' || role === 'system';
        return this.transitions
            .filter(t => t.from.includes(fromStatus))
            .filter(t => isSuperAdminOrSystem || t.allowedRoles.some(r => r.toLowerCase() === role || (r === 'partner_bank' && role === 'bank')))
            .map(t => t.to);
    }
    static isTerminalState(status) {
        const s = status?.toLowerCase();
        return ['closed', 'rejected', 'expired'].includes(s);
    }
}
exports.LoanStateMachine = LoanStateMachine;
//# sourceMappingURL=loan-state-machine.js.map