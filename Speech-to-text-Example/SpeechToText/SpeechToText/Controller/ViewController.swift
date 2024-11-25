//
//  ViewController.swift
//  SpeechToText
//
//  Created by Deepak Singh on 25/11/24.
//

import UIKit
import Combine

enum ChatType {
    case system
    case user
}

class ChatModel {
    var type: ChatType
    var message: String
    init(type: ChatType, message: String) {
        self.type = type
        self.message = message
    }
}

class ViewController: UIViewController, ActionSheetPresentable {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var labelCurrentTranscription: UILabel!
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindToLive()
        startAI()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - IBActions
    @IBAction func tapClose(_ sender: Any) {
        self.showAlert(
            title: "Stop AI",
            message: "Do you want to stop Sully Voice Assistance?",
            buttons: ["No", "Yes"]
        ) { [weak self] index in
            if index == 1 {
                self?.stopAI()
                self?.dismiss(animated: true)
            }
        }
    }
    
    @IBAction func tapBack(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

// MARK: - Private Methods
extension ViewController {
    
    private func setupUI() {
        self.view.backgroundColor = .clear
        tableView.register(UINib(nibName: "SystemCell", bundle: nil), forCellReuseIdentifier: "SystemCell")
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "UserCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func startAI() {
        tableView.isHidden = false
        Live.shared.startSession()
    }
    
    private func stopAI() {
        Live.shared.endSession()
    }
    
    private func updateTranscriptionDisplay(text: String?) {
        if let text {
            labelCurrentTranscription.text = text
            tableView.isHidden = true
        } else {
            labelCurrentTranscription.text = nil
            tableView.isHidden = false
        }
    }
    
    private func bindToLive() {
        // Bind transcription updates
        Live.shared.$currentTranscription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.updateTranscriptionDisplay(text: text)
            }
            .store(in: &cancellables)
        
        // Bind error updates
        Live.shared.$currentError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showMessage(message: error.localizedDescription)
                }
            }
            .store(in: &cancellables)
        
        // Bind listening state
        Live.shared.listeningStateChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleListeningState(state)
            }
            .store(in: &cancellables)
        
        // Bind conversations
        Live.shared.$conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadTable()
            }
            .store(in: &cancellables)
        
    }
    
    private func reloadTable() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.scrollToBottom()
            }
        }
    }
    
    private func handleListeningState(_ state: ListeningState) {
        switch state {
        case .active:
            self.activityIndicator.stopAnimating()
            
        case .processing:
            self.activityIndicator.startAnimating()
            
        case .inactive:
            self.activityIndicator.stopAnimating()
            
        case .error(let error):
            if error.localizedDescription.contains("No speech detected") {
                self.showMessage(message: error.localizedDescription)
            }
        }
    }
    
    
    private func scrollToBottom() {
        guard Live.shared.conversations.count > 0 else { return }
        let lastRow = Live.shared.conversations.count - 1
        let indexPath = IndexPath(row: lastRow, section: 0)
        if self.tableView.numberOfSections > 0,
           self.tableView.numberOfRows(inSection: 0) > lastRow {
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    private func showMessage(message: String) {
        self.showMessage(message: message, title: "DSN Repo", onDismiss: {
            
        })
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Live.shared.conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = Live.shared.conversations[indexPath.row]
        switch model.type {
        case .system:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SystemCell", for: indexPath) as? SystemCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.populateCell(model: model)
            return cell
        case .user:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as? UserCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.populateCell(model: model)
            return cell
        }
    }
}


