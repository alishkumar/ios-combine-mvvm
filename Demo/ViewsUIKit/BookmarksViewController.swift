//
//  BookmarksViewController.swift
//  Demo
//
//  Created by Alish Kumar on 13/02/26.
//


import UIKit
import Combine

final class BookmarksViewController: UIViewController {
    private let viewModel: NewsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 120
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No bookmarked articles"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(viewModel: NewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadBookmarkedArticles()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Bookmarks"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NewsTableViewCell.self, forCellReuseIdentifier: NewsTableViewCell.identifier)
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$bookmarkedArticles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] articles in
                guard let self = self else { return }
                let wasEmpty = self.emptyStateLabel.isHidden == false
                
                self.tableView.reloadData()
                
                if articles.isEmpty && !wasEmpty {
                    self.emptyStateLabel.alpha = 0
                    self.emptyStateLabel.isHidden = false
                    UIView.animate(withDuration: 0.3) {
                        self.emptyStateLabel.alpha = 1.0
                    }
                } else if !articles.isEmpty && wasEmpty {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.emptyStateLabel.alpha = 0
                    }) { _ in
                        self.emptyStateLabel.isHidden = true
                    }
                }
            }
            .store(in: &cancellables)
    }
}

extension BookmarksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.bookmarkedArticles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.bookmarkedArticles.count else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsTableViewCell.identifier, for: indexPath) as! NewsTableViewCell
        cell.configure(with: viewModel.bookmarkedArticles[indexPath.row])
        
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: -20, y: 0)
        
        UIView.animate(withDuration: 0.4, delay: Double(indexPath.row) * 0.05, options: [.curveEaseOut], animations: {
            cell.alpha = 1.0
            cell.transform = .identity
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.bookmarkedArticles.count else { return }
        let article = viewModel.bookmarkedArticles[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.2, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    cell.transform = .identity
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let detailVC = NewsDetailViewController(article: article, viewModel: self.viewModel)
            detailVC.view.alpha = 0
            self.navigationController?.pushViewController(detailVC, animated: false)
            
            UIView.animate(withDuration: 0.3) {
                detailVC.view.alpha = 1.0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard indexPath.row < viewModel.bookmarkedArticles.count else { return }
            let article = viewModel.bookmarkedArticles[indexPath.row]
            viewModel.toggleBookmark(for: article)
        }
    }
}
