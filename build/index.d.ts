import { PDFToolkitModuleType } from "./PDFToolkit.types";
import PDFToolkitDefault from "./PDFToolkitModule";
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
export declare const PDFToolkit: PDFToolkitModuleType;
export default PDFToolkitDefault;
//# sourceMappingURL=index.d.ts.map