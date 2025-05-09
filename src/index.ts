// Reexport the native module. On web, it will be resolved to PDFToolkitModule.web.ts
// and on native platforms to PDFToolkitModule.ts

// 1. 명시적 export - 자동완성을 위해 recommended
import type { PDFToolkitModuleType } from "./PDFToolkit.types";
import PDFToolkitModule from "./PDFToolkitModule";

// Export the native module as PDFToolkit for named import
export const PDFToolkit: PDFToolkitModuleType = PDFToolkitModule;

// 2. 기존 default export - 이전 코드 호환성 유지
export default PDFToolkitModule;

// 3. type exports
export * from "./PDFToolkit.types";
