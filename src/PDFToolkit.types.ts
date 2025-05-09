export type PDFToolkitModuleEvents = {
  onProgress: (event: {
    progress: number;
    page: number;
    total: number;
  }) => void;
};

/**
 * PDF 변환 옵션 타입
 */
export interface PDFConversionOptions {
  /**
   * 이미지 크기 비율 (1.0 = 원본 크기)
   * 예: 0.5 = 50% 크기, 2.0 = 200% 크기
   */
  scale?: number;

  /**
   * 이미지 압축률 (0.0 ~ 1.0, 기본값: 0.7)
   * 1.0은 최대 품질(최소 압축), 0.0은 최저 품질(최대 압축)
   */
  compressionQuality?: number;
}

/**
 * PDFToolkit 네이티브 모듈 타입
 */
export interface PDFToolkitModuleType {
  /**
   * 이벤트 리스너 추가
   * @param eventName 이벤트 이름
   * @param listener 콜백 함수
   */
  addListener(eventName: string, listener: (...args: any[]) => void): void;

  /**
   * 모든 이벤트 리스너 제거
   * @param eventName 이벤트 이름
   */
  removeAllListeners(eventName: string): void;

  /**
   * PDF 파일의 모든 페이지를 이미지로 변환
   * @param pdfPath PDF 파일 경로
   * @param options 변환 옵션
   * @returns 이미지 경로 리스트
   */
  convertToImages(
    pdfPath: string,
    options?: PDFConversionOptions
  ): Promise<string[]>;

  /**
   * PDF 파일의 이름만 추출
   * @param pdfPath PDF 파일 경로
   * @returns 파일명 (경로 제외, 확장자 포함)
   */
  getFileName(pdfPath: string): Promise<string>;

  /**
   * PDF 파일의 특정 페이지만 이미지로 변환
   * @param pdfPath PDF 파일 경로
   * @param pageNumber 페이지 번호 (0부터 시작)
   * @param options 변환 옵션
   * @returns 변환된 이미지 경로
   */
  getPageThumbnail(
    pdfPath: string,
    pageNumber: number,
    options?: PDFConversionOptions
  ): Promise<string>;
}
