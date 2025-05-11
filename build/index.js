"use strict";
/**
 * PDF 도구 모듈
 * 네이티브 플랫폼에서는 PDFToolkitModule.ts로 연결되고
 * 웹에서는 PDFToolkitModule.web.ts로 연결됩니다.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PDFToolkit = void 0;
const PDFToolkitModule_1 = __importDefault(require("./PDFToolkitModule"));
__exportStar(require("./PDFToolkit.types"), exports);
/**
 * PDF Toolkit 모듈
 * PDF 파일 관련 기능 제공
 * @example
 * import { PDFToolkit } from 'expo-pdf-toolkit';
 * // 여러 페이지 이미지로 변환
 * const images = await PDFToolkit.convertToImages(pdfPath, { scale: 1.0 });
 * // 특정 페이지 썸네일 얻기
 * const thumbnail = await PDFToolkit.getPageThumbnail(pdfPath, 0, { scale: 0.5 });
 */
exports.PDFToolkit = PDFToolkitModule_1.default;
// 기존 방식 호환을 위한 default export
exports.default = PDFToolkitModule_1.default;
//# sourceMappingURL=index.js.map