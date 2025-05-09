import { NativeModule } from "expo";
import { PDFToolkitModuleEvents, PDFConversionOptions } from "./PDFToolkit.types";
declare class PDFToolkitModule extends NativeModule<PDFToolkitModuleEvents> {
    convertToImages(pdfPath: string, options: PDFConversionOptions): Promise<string[]>;
    getPageThumbnail(pdfPath: string, pageNumber: number, options: PDFConversionOptions): Promise<string>;
    getFileName(pdfPath: string): Promise<string>;
}
declare const _default: PDFToolkitModule;
export default _default;
//# sourceMappingURL=PDFToolkitModule.d.ts.map