import PDFToolkitDefault from "./PDFToolkitModule";
// Export all types
export * from "./PDFToolkit.types";
/**
 * PDF Toolkit 모듈 - IDE 자동완성 용도로 명시적 타입 정의
 * @example
 * // 사용 예시
 * import { PDFToolkit } from 'expo-pdf-toolkit';
 * PDFToolkit.convertToImages('file://path/to/pdf', { scale: 1.0 });
 * PDFToolkit.getPageThumbnail('file://path/to/pdf', 0, { scale: 0.5 });
 * PDFToolkit.addListener('onProgress', ({ progress, page, total }) => {
 *   console.log(`진행률: ${progress * 100}%, 페이지: ${page}/${total}`);
 * });
 */
export const PDFToolkit = PDFToolkitDefault;
// Keep default export for backward compatibility
export default PDFToolkitDefault;
//# sourceMappingURL=index.js.map