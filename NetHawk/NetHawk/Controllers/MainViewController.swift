//
//  MainViewController2.swift
//  NetHawk
//
//  Created by mobicom on 9/10/24.
//

import UIKit
import UserNotifications
import FSPagerView

class MainViewController: UIViewController, FSPagerViewDataSource, FSPagerViewDelegate {

    // MARK: - FSPagerView
    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")

            // 화면 크기에 비례한 아이템 크기 설정
            if UIDevice.current.userInterfaceIdiom == .pad {
                let screenWidth = UIScreen.main.bounds.width
                let itemWidth = screenWidth * 0.4
                let itemHeight = itemWidth * 135/155
                self.pagerView.itemSize = CGSize(width: itemWidth, height: itemHeight)
                self.pagerView.interitemSpacing = 80
                self.pagerView.isInfinite = true
                self.pagerView.transformer = FSPagerViewTransformer(type: .overlap)
            } else {
                let screenWidth = UIScreen.main.bounds.width
                let itemWidth = screenWidth * 0.65
                let itemHeight = itemWidth * 135/155
                self.pagerView.itemSize = CGSize(width: itemWidth, height: itemHeight)
                self.pagerView.interitemSpacing = 50
                self.pagerView.isInfinite = true
                self.pagerView.transformer = FSPagerViewTransformer(type: .ferrisWheel)
            }
        }
    }

    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return images.count // 총 4개의 페이지
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)

        // SF Symbol 이미지 설정
        if let imageView = cell.imageView {
            imageView.image = UIImage(named: images[index])
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 24 // 이미지도 모서리를 둥글게
            imageView.layer.masksToBounds = true
        }

        return cell
    }

    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true) // 선택된 상태 해제

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        switch index {
        case 0:
            // 첫 번째 페이지로 이동
            if let firstVC = storyboard.instantiateViewController(withIdentifier: "LogViewController") as? LogViewController {
                firstVC.modalPresentationStyle = .fullScreen
                present(firstVC, animated: true, completion: nil)
            }
        case 1:
            // 두 번째 페이지로 이동
            if let secondVC = storyboard.instantiateViewController(withIdentifier: "StatViewController") as? StatViewController {
                secondVC.modalPresentationStyle = .fullScreen
                present(secondVC, animated: true, completion: nil)
            }
        case 2:
            // 세 번째 페이지로 이동
            if let thirdVC = storyboard.instantiateViewController(withIdentifier: "AccessViewController") as? AccessViewController {
                thirdVC.modalPresentationStyle = .fullScreen
                present(thirdVC, animated: true, completion: nil)
            }
        case 3:
            // 네 번째 페이지로 이동
            if let fourVC = storyboard.instantiateViewController(withIdentifier: "OptionViewController") as? OptionViewController {
                // 화면 중앙에서 시트처럼 올라오게 설정
                fourVC.modalPresentationStyle = .pageSheet

                if let sheet = fourVC.sheetPresentationController {
                    // 시트 크기 설정
                    sheet.detents = [.large(), .medium()]

                    // 모서리 둥글기 설정
                    sheet.preferredCornerRadius = 24

                    // 그래버 표시
                    sheet.prefersGrabberVisible = true

                    // 배경 딤 처리
                    sheet.largestUndimmedDetentIdentifier = nil

                    // 스크롤 시 확장 방지
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = true

                    // 드래그로 닫기 가능
                    sheet.prefersEdgeAttachedInCompactHeight = true

                    // 상단 여백 설정
                    sheet.selectedDetentIdentifier = .medium
                }

                // 모달 스타일 설정
                fourVC.modalPresentationStyle = .pageSheet

                present(fourVC, animated: true, completion: nil)
            }

        default:
            break
        }
    }

    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    let images = ["loger", "stat", "bw", "option"]

    // MARK: - UI
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUIForDevice()
        self.pagerView.dataSource = self
        self.pagerView.delegate = self

        if let credentials = KeychainManager.shared.load() {
            // let serialNumber = credentials.serialNumber
            let alias = credentials.alias

            deviceLabel.text = "\(alias)"

        }

        frameConfig(to: statusView)

        // MQTT 초기 상태 업데이트
        updateStatusLabel()

        // MQTTService에서 상태 콜백 등록
        setupMQTTStatusCallbacks()

        // 알림 권한 요청
        requestNotificationAuthorization()
    }

    // TODO: 사용자가 외부에서 알림 권한을 제거한 경우? --> 추후 생각이 필요할듯.
    // 알림 권한 요청
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()

        let alreadyAuthed = UserDefaults.standard.bool(forKey: "alreadyAuthed")

        if !alreadyAuthed {
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("Notification authorization error: \(error)")
                    // 권한 요청이 실패했거나 거부된 경우
                    UserDefaults.standard.set(1, forKey: "notificationEnabled")
                } else {
                    // 권한 요청이 성공적으로 승인된 경우
                    UserDefaults.standard.set(0, forKey: "notificationEnabled")
                }
                UserDefaults.standard.set(true, forKey: "alreadyAuthed")
            }
        }
    }

    func frameConfig(to view: UIView) {
        let cornerRadius: CGFloat = 10
        let shadowColor: UIColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.gray : UIColor.black
        }
        let shadowOpacity: Float = 0.3
        let shadowOffset: CGSize = CGSize(width: 0, height: 2)
        let shadowRadius: CGFloat = 4

        // 기본 그림자 설정
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = false
        view.layer.shadowColor = shadowColor.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowOffset = shadowOffset
        view.layer.shadowRadius = shadowRadius

        // 다크모드일 때 Glow 효과 추가
        if traitCollection.userInterfaceStyle == .dark {
            let glowLayer = CALayer()
            glowLayer.frame = view.bounds
            glowLayer.cornerRadius = cornerRadius
            glowLayer.shadowColor = UIColor.white.withAlphaComponent(0.5).cgColor
            glowLayer.shadowOpacity = 1.0
            glowLayer.shadowRadius = 30 // Glow 크기
            glowLayer.shadowOffset = CGSize.zero
            glowLayer.backgroundColor = UIColor.label.cgColor
            // Glow Layer를 레이어 맨 위에 추가
            view.layer.insertSublayer(glowLayer, at: 0)
        }
    }



    func setupUIForDevice() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // statusView 크기 조정
            statusView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusView.heightAnchor.constraint(equalToConstant: 120),
                statusView.widthAnchor.constraint(equalToConstant: 350),
            ])

            // deviceLabel 크기 및 폰트 조정
            deviceLabel.font = deviceLabel.font.withSize(22)
            deviceLabel.textColor = .black
            deviceLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                deviceLabel.heightAnchor.constraint(equalToConstant: 50),
            ])

            // statusLabel 크기 및 폰트 조정
            statusLabel.font = statusLabel.font.withSize(20)
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusLabel.heightAnchor.constraint(equalToConstant: 20),
            ])

            if let spacingConstraint = view.constraints.first(where: {
                ($0.firstItem as? UIView == pagerView && $0.secondItem as? UIView == statusView && $0.firstAttribute == .top && $0.secondAttribute == .bottom)
            }) {
                spacingConstraint.constant = 80 // 새로운 간격 값 설정
            } else {
                // 제약 조건이 없으면 새로 추가
                pagerView.translatesAutoresizingMaskIntoConstraints = false
                statusView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    pagerView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 80) // 원하는 간격 설정
                ])
            }
        }
    }


    // MARK: - MQTT 상태 설정
    func setupMQTTStatusCallbacks() {
        //        MQTTService.shared.onPingReceived = { [weak self] in
        //            DispatchQueue.main.async {
        //                self?.animateStatusViewExpansion()
        //                self?.statusLabel.text = "Checking connection..."
        //                self?.statusLabel.textColor = .gray
        //            }
        //        }

        MQTTService.shared.onPongReceived = { [weak self] in
            DispatchQueue.main.async {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self?.animateStatusViewCollapse()
                } else {
                    self?.statusLabel.text = "Server Online 🟢"
                    self?.statusLabel.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
                }
            }
        }

        MQTTService.shared.onDisconnected = { [weak self] in
            DispatchQueue.main.async {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self?.animateStatusViewExpansion()
                } else {
                    self?.statusLabel.text = "Checking connection... 🟠"
                    self?.statusLabel.textColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
                }
            }
        }

        MQTTService.shared.onConnectionSuccess = { [weak self] in
            DispatchQueue.main.async {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self?.animateStatusViewCollapse()
                } else {
                    self?.statusLabel.text = "Server Online 🟢"
                    self?.statusLabel.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
                }
            }}
    }

    func updateStatusLabel() {
        if MQTTService.shared.isConnected() {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.animateStatusViewCollapse()
            } else {
                self.statusLabel.text = "Server Online 🟢"
                self.statusLabel.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            }
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.animateStatusViewExpansion()
            } else {
                self.statusLabel.text = "Checking connection... 🟠"
                self.statusLabel.textColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
            }
        }
    }

    func animateStatusViewExpansion() {

        // 기존 width 제약 조건 제거
        if let existingWidthConstraint = statusView.constraints.first(where: { $0.firstAttribute == .width }) {
            NSLayoutConstraint.deactivate([existingWidthConstraint])
        }

        // 새로운 width 제약 조건 추가
        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusView.widthAnchor.constraint(equalToConstant: 350) // 확장 크기 설정
        ])

        // 스프링 애니메이션 사용
        UIView.animate(
            withDuration: 0.6, // 애니메이션 지속 시간
            delay: 0, // 지연 시간
            usingSpringWithDamping: 0.7, // 탄성 효과 조정
            initialSpringVelocity: 1.0, // 초기 속도
            options: [], // 추가 옵션 없음
            animations: {
                self.view.layoutIfNeeded() // 레이아웃 변경
            }, completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    self.statusLabel.text = "Checking connection... 🟠"
                    self.statusLabel.textColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
                }
            }
        )
    }

    func animateStatusViewCollapse() {
        // 기존 width 제약 조건 제거
        if let existingWidthConstraint = statusView.constraints.first(where: { $0.firstAttribute == .width }) {
            NSLayoutConstraint.deactivate([existingWidthConstraint])
        }

        // 새로운 width 제약 조건 추가
        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusView.widthAnchor.constraint(equalToConstant: 234) // 축소 크기 설정
        ])

        // 스프링 애니메이션 사용
        UIView.animate(
            withDuration: 0.6, // 애니메이션 지속 시간
            delay: 0, // 지연 시간
            usingSpringWithDamping: 0.7, // 탄성 효과 조정
            initialSpringVelocity: 1.0, // 초기 속도
            options: [], // 추가 옵션 없음
            animations: {
                self.view.layoutIfNeeded() // 레이아웃 변경
                self.statusLabel.text = "Server Online 🟢"
                self.statusLabel.textColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            }, completion: nil
        )
    }
}
