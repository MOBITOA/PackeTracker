//
//  ConnectionViewController.swift
//  NetHawk
//
//  Created by mobicom on 6/6/24.
//

import UIKit
import CocoaMQTT

class ConnectionViewController: UIViewController {

    // MARK: - UI Outlets
    @IBOutlet weak var logoLabel: UIButton!
    @IBOutlet weak var inputLabelOne: UILabel!
    @IBOutlet weak var inputLabelTwo: UILabel!
    @IBOutlet weak var tfFrameOne: UIView!
    @IBOutlet weak var tfFrameTwo: UIView!
    @IBOutlet weak var serialNumberTextField: UITextField!
    @IBOutlet weak var aliasTextField: UITextField!
    @IBOutlet weak var pairingBtn: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!

    private var mqttService: MQTTService?

    // MARK: - LifeCycle and UI Design
    override func viewDidLoad() {
        super.viewDidLoad()
        print("----------------")
        print("viewDidLoad : ConnectionView")
        self.logoLabel.alpha = 0.0
        self.inputLabelOne.alpha = 0.0
        self.inputLabelTwo.alpha = 0.0
        self.tfFrameOne.alpha = 0.0
        self.tfFrameTwo.alpha = 0.0
        self.pairingBtn.alpha = 0.0
        self.logoImageView.alpha = 0.0
        self.serialNumberTextField.text = ""
        self.aliasTextField.text = ""

        frameConfig(to: tfFrameOne)
        frameConfig(to: tfFrameTwo)

        serialNumberTextField.delegate = self
        aliasTextField.delegate = self

        // 탭 제스처 추가: 화면의 다른 부분을 터치했을 때 키보드를 닫음
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        // X 버튼 활성화
        serialNumberTextField.clearButtonMode = .whileEditing
        aliasTextField.clearButtonMode = .whileEditing
    }

    /*
     SplashView에서 DispatchQueue.main.asyncAfter를 사용하여
     일정 시간 지연 후에 본 페이지로 오기 때문에 타이밍 문제가 존재했음.
     viewDidAppear로 이전 타이밍이 끝나고 본 작업을 시행
     */
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.applyAnimations()
        }
    }

    func frameConfig(to view: UIView) {
        let cornerRadius: CGFloat = 10
        let shadowColor: UIColor = .black
        let shadowOpacity: Float = 0.3
        let shadowOffset: CGSize = CGSize(width: 0, height: 2)
        let shadowRadius: CGFloat = 4

        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = false
        view.layer.shadowColor = shadowColor.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowOffset = shadowOffset
        view.layer.shadowRadius = shadowRadius
    }

    func applyAnimations() {
        UIView.animate(withDuration: 1, delay: 0.1, options: .curveEaseInOut, animations: {
            self.logoLabel.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.3, options: .curveEaseInOut, animations: {
            self.inputLabelOne.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseInOut, animations: {
            self.tfFrameOne.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.7, options: .curveEaseInOut, animations: {
            self.inputLabelTwo.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 0.9, options: .curveEaseInOut, animations: {
            self.tfFrameTwo.alpha = 1.0
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 1.1, options: .curveEaseInOut, animations: {
            self.pairingBtn.alpha = 1.0
            self.pairingBtn.isEnabled = false
        }, completion: nil)

        UIView.animate(withDuration: 1, delay: 1.3, options: .curveEaseInOut, animations: {
            self.logoImageView.alpha = 0.1
        }, completion: nil)
    }

    // MARK: - Methods

    // 페어링 버튼 클릭 메서드
    @IBAction func pairingBtnTapped(_ sender: UIButton) {
        let serialNumber = serialNumberTextField.text ?? ""
        let alias = aliasTextField.text ?? ""

        // 브로커 정보 저장
        KeychainManager.shared.save(serialNumber: serialNumber, alias: alias)

        /*
         MQTT Broker IP/Port - 학교망 외부에서
         host : 203.230.104.207
         port : 80

         MQTT Broker IP/Port - 학교망 내부에서
         host : 203.230.104.207
         port : 14025
         */
        mqttService = MQTTService(clientID: alias, host: "203.230.104.207", port: 14025)
        mqttService?.onConnectionSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.navigateToMainViewController()
            }
        }
        mqttService?.onConnectionFailure = { [weak self] in
            DispatchQueue.main.async {
                self?.presentConnectionErrorAlert()
            }
        }
        mqttService?.connect()

        // navigateToMainViewController()
    }
    // 연결 실패 시, 알림창
    func presentConnectionErrorAlert() {

        let alert = UIAlertController(title: "Connection Error", message: "Unable to connect to MQTT broker. Please check the details and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { [weak self] _ in
            self?.pairingBtnTapped(UIButton())
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    // MainView 이동 메서드
    private func navigateToMainViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController {

            if let navigationController = navigationController {
                navigationController.pushViewController(mainViewController, animated: true)
            } else {
                mainViewController.modalPresentationStyle = .fullScreen
                present(mainViewController, animated: true, completion: nil)
            }
        } else {}
    }
}

extension ConnectionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 시리얼 넘버 텍스트 필드 입력 시
        if textField == serialNumberTextField || textField == aliasTextField {
            let serialNumberIsEmpty = serialNumberTextField.text?.isEmpty ?? true
            let aliasIsEmpty = aliasTextField.text?.isEmpty ?? true

            // 두 텍스트 필드가 모두 채워져 있으면 버튼 활성화
            if serialNumberIsEmpty || aliasIsEmpty {
                pairingBtn.isEnabled = false
            } else {
                pairingBtn.isEnabled = true
            }
            return true
        }
        return true
    }
    // 키보드를 숨기는 메서드
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}



