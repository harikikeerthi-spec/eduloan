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
Object.defineProperty(exports, "__esModule", { value: true });
exports.GradeConversionService = void 0;
const common_1 = require("@nestjs/common");
const openrouter_service_1 = require("./openrouter.service");
let GradeConversionService = class GradeConversionService {
    openRouter;
    constructor(openRouter) {
        this.openRouter = openRouter;
    }
    async convertGrade(input) {
        if (input.inputType === 'percentage') {
            const val = Number(input.inputValue);
            if (isNaN(val) || val < 0 || val > 100) {
                throw new common_1.BadRequestException('Percentage must be a number between 0 and 100');
            }
        }
        if (input.inputType === 'marks') {
            const val = Number(input.inputValue);
            const total = Number(input.totalMarks ?? 100);
            if (isNaN(val) || val < 0) {
                throw new common_1.BadRequestException('Marks must be a non-negative number');
            }
            if (isNaN(total) || total <= 0) {
                throw new common_1.BadRequestException('totalMarks must be a positive number');
            }
            if (val > total) {
                throw new common_1.BadRequestException(`Marks (${val}) cannot exceed total marks (${total})`);
            }
        }
        if (input.inputType === 'gpa') {
            const val = Number(input.inputValue);
            const maxGpa = 4.0;
            if (isNaN(val) || val < 0 || val > maxGpa) {
                throw new common_1.BadRequestException(`GPA must be a number between 0 and ${maxGpa}`);
            }
        }
        if (input.inputType === 'cgpa') {
            const val = Number(input.inputValue);
            const maxCgpa = 10.0;
            if (isNaN(val) || val < 0 || val > maxCgpa) {
                throw new common_1.BadRequestException(`CGPA must be a number between 0 and ${maxCgpa}`);
            }
        }
        const prompt = `
    Convert the following academic grade:
    - Value: ${input.inputValue}
    - Type: ${input.inputType}
    - Maximum/Total: ${input.totalMarks || 'N/A'}
    - Grading System: ${input.gradingSystem || 'Global Standard'}
    
    Target Output: ${input.outputType}

    CRITICAL CONSTRAINTS:
    - If the input Type is 'percentage', the Value is a literal percentage out of 100. You MUST NEVER scale, multiply, or auto-correct the percentage value, even if it is extremely low (e.g., an input value of 10.5 represents a literal 10.5% out of 100%, NOT 105%, and NOT 10.5 CGPA). Keep the percentage output exactly equal to the input percentage value.
    - If the input Type is 'cgpa', the Value is out of 10.0.
    - If the input Type is 'gpa', the Value is out of 4.0.
    - If the input Type is 'marks', compute the percentage as (Value / Maximum) * 100.

    Perform a strictly accurate conversion.
    Also provide:
    1. Standardized Percentage (0-100)
    2. GPA (4.0 scale)
    3. CGPA (10.0 scale)
    4. Letter Grade (US Standard)
    5. Classification (First Class, etc.)
    6. Equivalent grades for US, UK, and India.
    7. A brief textual analysis of the grade strength and 3 recommendations.

    Return JSON format:
    {
      "inputGrade": "string representation",
      "outputGrade": "string representation",
      "percentage": number,
      "gpa": number,
      "cgpa": number,
      "letterGrade": "string",
      "classification": "string",
      "internationalEquivalent": {
        "US": "string",
        "UK": "string",
        "India": "string"
      },
      "analysis": {
        "strength": "string",
        "competitiveness": "string",
        "recommendations": ["string"]
      }
    }
    `;
        try {
            const result = await this.openRouter.getJson(prompt);
            if (result) {
                if (!result.analysis) {
                    result.analysis = { strength: '', competitiveness: '', recommendations: [] };
                }
                result.analysis.percentage = result.analysis.percentage ?? result.percentage;
                result.analysis.gpa = result.analysis.gpa ?? result.gpa;
                result.analysis.cgpa = result.analysis.cgpa ?? result.cgpa;
            }
            return result;
        }
        catch (error) {
            console.error('Grade conversion failed', error);
            return {
                inputGrade: String(input.inputValue),
                outputGrade: 'N/A',
                percentage: 0,
                gpa: 0,
                cgpa: 0,
                letterGrade: 'N/A',
                classification: 'N/A',
                internationalEquivalent: { US: 'N/A', UK: 'N/A', India: 'N/A' },
                analysis: { strength: 'Error', competitiveness: 'Service unavailable', recommendations: [] }
            };
        }
    }
    async comparePerformance(assessments) {
        const prompt = `
      Analyze the performance trend based on these assessments:
      ${JSON.stringify(assessments)}

      Return JSON:
      {
        "trend": "string (e.g. Upward, Downward, Stable)",
        "averagePerformance": number,
        "bestPerformance": "string (subject name)",
        "worstPerformance": "string (subject name)",
        "progression": "string (e.g. Improving, Declining)"
      }
      `;
        try {
            return await this.openRouter.getJson(prompt);
        }
        catch (error) {
            console.error('Performance comparison failed', error);
            return {
                trend: 'Error',
                averagePerformance: 0,
                bestPerformance: 'N/A',
                worstPerformance: 'N/A',
                progression: 'N/A'
            };
        }
    }
};
exports.GradeConversionService = GradeConversionService;
exports.GradeConversionService = GradeConversionService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [openrouter_service_1.OpenRouterService])
], GradeConversionService);
//# sourceMappingURL=grade-conversion.service.js.map