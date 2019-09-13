//
//  CellConfigurator.swift
//  development-pods-instantsearch
//
//  Created by Vladislav Fitc on 12/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import SDWebImage
import InstantSearchCore

struct MovieCellViewState {
  
  func configure(_ cell: UIView & MovieCell) -> (Movie) -> () {
    return { movie in
      cell.artworkImageView.sd_setImage(with: movie.image) { (_, _, _, _) in
        DispatchQueue.main.async {
          cell.setNeedsLayout()
        }
      }
      cell.titleLabel.text = movie.title
      cell.genreLabel.text = movie.genre.joined(separator: ", ")
      cell.yearLabel.text = String(movie.year)
    }
  }
  
}

struct MovieHitCellViewState {
  
  func configure(_ cell: UIView & MovieCell) -> (Hit<Movie>) -> () {
    return { movieHit in
      let movie = movieHit.object
      cell.artworkImageView.sd_setImage(with: movie.image) { (_, _, _, _) in
        DispatchQueue.main.async {
          cell.setNeedsLayout()
        }
      }
      
//      if let highlightedTitles = movieHit.highlightResult?["title"] {
//        cell.titleLabel.attributedText = NSAttributedString(highlightedResults: highlightedTitles, separator: NSAttributedString(string: ", "), attributes: [.foregroundColor: UIColor.red])
//      }

      cell.genreLabel.text = movie.genre.joined(separator: ", ")
      cell.yearLabel.text = String(movie.year)
    }
  }

  
}

struct ActorCollectionViewCellViewState {
  
  func configure(_ cell: ActorCollectionViewCell) -> (Actor) -> () {
    return { actor in
      cell.nameLabel.text = actor.name
    }
  }
  
}

struct ActorHitCollectionViewCellViewState {
  
  func configure(_ cell: ActorCollectionViewCell) -> (Hit<Actor>) -> () {
    return { actorHit in
//      if let highlightedNames = actorHit.highlightResult?["name"] {
//        cell.nameLabel.attributedText = NSAttributedString(highlightedResults: highlightedNames, separator: NSAttributedString(string: ", "), attributes: [.foregroundColor: UIColor.red])
//      }
    }
  }
  
}



protocol CellConfigurable {
  associatedtype T
  static func configure(_ cell: UITableViewCell) -> (T) -> Void
}

struct EmptyCellConfigurator: CellConfigurable {
  static func configure(_ cell: UITableViewCell) -> (Any) -> Void {
    return { _ in }
  }
}

struct MovieCellConfigurator: CellConfigurable {
  
  static func configure(_ cell: UITableViewCell) -> (Movie) -> Void {
    return { movie in
      cell.textLabel?.text = movie.title
      cell.detailTextLabel?.text = movie.genre.joined(separator: ", ")
      cell.imageView?.sd_setImage(with: movie.image, completed: { (_, _, _, _) in
        cell.setNeedsLayout()
      })
    }
  }
  
}

struct ActorCellConfigurator: CellConfigurable {
  
  static func configure(_ cell: UITableViewCell) -> (Actor) -> Void {
    return { actor in
      cell.textLabel?.text = actor.name
      cell.detailTextLabel?.text = "rating: \(actor.rating)"
      let baseImageURL = URL(string: "https://image.tmdb.org/t/p/w45")
      let imageURL = baseImageURL?.appendingPathComponent(actor.image_path)
      cell.imageView?.sd_setImage(with: imageURL, completed: { (_, _, _, _) in
        cell.setNeedsLayout()
      })
    }
  }

}

struct MovieHitCellConfigurator: CellConfigurable {
  
  static func configure(_ cell: UITableViewCell) -> (Hit<Movie>) -> Void {
    return { movieHit in
      let movie = movieHit.object
//      if let highlightedTitles = movieHit.highlightResult?["title"] {
//        cell.textLabel?.attributedText = NSAttributedString(highlightedResults: highlightedTitles, separator: NSAttributedString(string: ", "), attributes: [.foregroundColor: UIColor.red])
//      }

      cell.detailTextLabel?.text = movie.genre.joined(separator: ", ")
      cell.imageView?.sd_setImage(with: movie.image, completed: { (_, _, _, _) in
        cell.setNeedsLayout()
      })
    }
  }
  
}
