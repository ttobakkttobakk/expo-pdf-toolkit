import { NativeModule, requireNativeModule } from "expo";

import { PDFToolkitModuleEvents } from "./PDFToolkit.types";

declare class PDFToolkitModule extends NativeModule<PDFToolkitModuleEvents> {
  convertToImages(pdfPath: string): Promise<string[]>;
  getFileName(pdfPath: string): Promise<string>;
  getPageThumbnail(pdfPath: string, pageNumber: number): Promise<string>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<PDFToolkitModule>("PDFToolkit");
