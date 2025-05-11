import { requireNativeModule } from "expo-modules-core";

import { PDFToolkitModuleType } from "./PDFToolkit.types";

// 이 호출은 JSI에서 네이티브 모듈 객체를 로드합니다.
export default requireNativeModule<PDFToolkitModuleType>("PDFToolkit");
