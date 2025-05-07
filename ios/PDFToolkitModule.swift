import ExpoModulesCore
import PDFKit
import UIKit

public class PDFToolkitModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('PDFToolkit')` in JavaScript.
    Name("PDFToolkit")

    // PDF를 이미지로 변환하는 메소드 정의
    AsyncFunction("convertToImages") { (pdfPath: String, promise: Promise) in
      // PDF 파일을 로드하고 실패시 에러 반환
      let path = pdfPath.replacingOccurrences(of: "file://", with: "")
      guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
        promise.reject(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDF 로드 실패"]))
        return
      }
      
      // PDF 파일 경로에서 파일명 추출 (확장자 제외)
      let pdfURL = URL(fileURLWithPath: path)
      let pdfNameWithoutExt = pdfURL.deletingPathExtension().lastPathComponent
      var imagePaths: [String] = []
      
      // 모든 PDF 페이지를 순회하며 이미지로 변환
      for pageIndex in 0..<doc.pageCount {
        guard let page = doc.page(at: pageIndex) else { continue }
        let pageRect = page.bounds(for: .mediaBox)
        
        // 페이지 크기에 맞는 이미지 렌더러 생성
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
          UIColor.white.set()
          ctx.fill(pageRect)

          let cgContext = ctx.cgContext
          let rotationAngle = page.rotationAngle

          if rotationAngle != 0 {
            // 중심점 기준으로 회전
            cgContext.translateBy(x: pageRect.size.width / 2, y: pageRect.size.height / 2)
            cgContext.rotate(by: CGFloat(rotationAngle) * CGFloat.pi / 180)
            cgContext.translateBy(x: -pageRect.size.width / 2, y: -pageRect.size.height / 2)
          }

          page.draw(with: .mediaBox, to: cgContext)
        }
        
        // 이미지를 JPEG로 변환하고 저장
        if let data = image.jpegData(compressionQuality: 0.7) {
          let timestamp = Int(Date().timeIntervalSince1970 * 1000)
          let fileName = "\(pdfNameWithoutExt)_\(timestamp)_page_\(pageIndex).jpg"
          let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
          try? data.write(to: URL(fileURLWithPath: filePath))
          imagePaths.append("file://" + filePath)
        }
      }
      
      // 변환된 이미지 경로들을 반환
      promise.resolve(imagePaths)
    }

    // 파일 이름을 가져오는 메소드 정의
    AsyncFunction("getFileName") { (pdfPath: String, promise: Promise) in
      let url = URL(fileURLWithPath: pdfPath)
      let fileName = url.lastPathComponent
      promise.resolve(fileName)
    }

    // PDF의 특정 페이지를 이미지로 변환하는 메소드 정의
    AsyncFunction("getPageThumbnail") { (pdfPath: String, pageNumber: Int, promise: Promise) in
      let path = pdfPath.replacingOccurrences(of: "file://", with: "")
      guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
        promise.reject(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "PDF 로드 실패"]))
        return
      }
      guard let page = doc.page(at: pageNumber) else {
        promise.reject(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "해당 페이지 없음"]))
        return
      }
      let pageRect = page.bounds(for: .mediaBox)
      let renderer = UIGraphicsImageRenderer(size: pageRect.size)
      let image = renderer.image { ctx in
        UIColor.white.set()
        ctx.fill(pageRect)
        let cgContext = ctx.cgContext
        let rotationAngle = page.rotationAngle
        if rotationAngle != 0 {
          cgContext.translateBy(x: pageRect.size.width / 2, y: pageRect.size.height / 2)
          cgContext.rotate(by: CGFloat(rotationAngle) * CGFloat.pi / 180)
          cgContext.translateBy(x: -pageRect.size.width / 2, y: -pageRect.size.height / 2)
        }
        page.draw(with: .mediaBox, to: cgContext)
      }
      if let data = image.jpegData(compressionQuality: 0.7) {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let pdfURL = URL(fileURLWithPath: path)
        let pdfNameWithoutExt = pdfURL.deletingPathExtension().lastPathComponent
        let fileName = "\(pdfNameWithoutExt)_\(timestamp)_page_\(pageNumber).jpg"
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        try? data.write(to: URL(fileURLWithPath: filePath))
        promise.resolve("file://" + filePath)
        return
      }
      promise.reject(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "이미지 변환 실패"]))
    }
  }
}
