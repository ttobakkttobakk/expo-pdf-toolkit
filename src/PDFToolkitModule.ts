import { NativeModule, requireNativeModule } from "expo";

import {
  PDFToolkitModuleEvents,
  PDFConversionOptions,
} from "./PDFToolkit.types";

declare class PDFToolkitModule extends NativeModule<PDFToolkitModuleEvents> {
  convertToImages(
    pdfPath: string,
    options: PDFConversionOptions
  ): Promise<string[]>;
  getPageThumbnail(
    pdfPath: string,
    pageNumber: number,
    options: PDFConversionOptions
  ): Promise<string>;
  getFileName(pdfPath: string): Promise<string>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<PDFToolkitModule>("PDFToolkit");
