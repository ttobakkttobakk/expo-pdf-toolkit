/**
 * PDF 도구 모듈
 * 네이티브 플랫폼에서는 PDFToolkitModule.ts로 연결되고
 * 웹에서는 PDFToolkitModule.web.ts로 연결됩니다.
 */

// 타입 정의 내보내기
// 구현체 가져오기
import { PDFToolkitModuleType } from "./PDFToolkit.types";
import PDFToolkitImpl from "./PDFToolkitModule";

export * from "./PDFToolkit.types";

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
export const PDFToolkit: PDFToolkitModuleType = PDFToolkitImpl;

// 기존 방식 호환을 위한 default export
export default PDFToolkitImpl;
